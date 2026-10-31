#!/bin/bash
#
# Ceph OSD lockbox key rotation script v0.5
# Author: Scott Shambarger <devel@shambarger.net>
#
# Copyright (C) Scott Shambarger
# SPDX-License-Identifier: GPL-3.0-or-later
#
declare -i rc=0

err() { echo "$*" >&2; (( rc != 0 )) || rc=1; }
die() { err "$*"; exit $rc; }
die_help() { die "$* (try --help)"; }

usage() {
  echo "Rotate ceph key for cephadm OSD services"
  echo "Usage: ${0##*/} --help | [ --debug ] [ --pause ] <id>..."
  echo "  --debug - show what would be done, no changes (dry-run)"
  echo "  --pause - ask to continue at each change"
  echo "  <id> is the number id of an OSD"
  exit $rc
}

PAUSE=''
pause() {
  [[ $PAUSE ]] || return 0
  local an=x IFS
  # regex borked on Darwan ^(y|n|)$ doesn't work??
  until [[ ${an,} =~ ^y$|^n$|^$ ]]; do read -rp "Continue (Y/n): " an; done
  [[ ${an,} =~ ^y$|^$ ]] || exit 1
}

shopt -s extglob

for cmd in ceph ceph-volume lvs jq; do
  command >/dev/null -v "$cmd" || err "Unable to find command $cmd"
done
(( rc == 0 )) || exit

debug=''
IDS=()
while [[ $1 ]]; do
  case $1 in
    -h|--help) usage;;
    -d|--debug) debug="echo DEBUG: ";;
    -p|--pause) PAUSE=1;;
    (+([0-9])) IDS+=("$1");;
    *) die_help "Unknown option $1";;
  esac
  shift
done

[[ ${IDS[0]} ]] || die_help "At least one <id> is required"

# verify connectivity
FSID=$(ceph fsid --connect-timeout 2) || :
[[ $FSID ]] || die "Unable to discover ceph fsid"

# check args
for id in "${IDS[@]}"; do
  [[ -s /var/lib/ceph/$FSID/osd.$id/lockbox.keyring ]] ||
    die "osd.$id not found on this host"
done

# verify preferred key
echo "Verifying preferred keytype..."
keytype=$(ceph 2>/dev/null --format=json mon dump |
            jq -r '.auth_preferred_cipher.name')
[[ $keytype == aes256k ]] || {
  err "Preferred keytype is currently '$keytype'"
  err "Update to aek256k with the following command and try again:"
  die "$ ceph mon set auth_preferred_cipher aes256k"
}
echo "   keytype is $keytype"

# LVM tag name
TAGNAME="ceph.cephx_lockbox_secret"

for id in "${IDS[@]}"; do
  ROOT="/var/lib/ceph/$FSID/osd.$id"

  echo
  echo "#### OSD.$id ####"
  echo "DIR: $ROOT"
  pushd >/dev/null "$ROOT" || die "Unable to access $ROOT"

  fsid=$(< fsid)
  [[ $fsid ]] || die "Unable to read $ROOT/fsid"

  kname="client.osd-lockbox.$fsid"
  key=$(ceph auth print-key "$kname")
  [[ $key ]] || die "Unable to find lockbox key for fsid $fsid"

  if [[ ${#key} == 40 ]]; then
    echo "Key for fsid $fsid needs to be rotated!"
  elif [[ ${#key} == 60 ]]; then
    echo "Key for fsid $fsid appears to be upgraded already"
  else
    die "Key for fsid $fsid has unexpected length ${#key}: '$key'"
  fi

  echo "confirming current status..."

  # first check lockbox.keyring
  lb=$(< lockbox.keyring)
  ckr=$(ceph auth get "$kname" | grep -v "caps ")

  [[ $lb == "$ckr" ]] || {
    err
    err "== FAILED validating lockbox.keyring =="
    err "lockbox.keyring:"
    err "$lb"
    err
    err "ceph auth key $kname:"
    err "$ckr"
    err
    die "Keys needs to be in sync to start"
  }
  echo " - lockbox.keyring matches ceph auth"

  # Now check LVM tags
  lvpath=$(ceph-volume lvm list --format json "$id" |
             jq -r ".\"$id\"[0].lv_path")
  [[ $lvpath ]] || die "Unable to locate LVM device path for osd.$id"
  tags=$(lvs --reportformat json -o Tags "$lvpath" |
           jq -r ".report[0].lv[0].lv_tags")
  [[ $tags ]] || die "Unable to locate LVM device tags for $lvpath"
  IFS=, read -r -a atags <<< "$tags"
  (( ${#atags[*]} > 0 )) || {
    err "Unable to parse LVM tags for $lvpath"
    die "Tags: $tags"
  }
  for tag in "${atags[@]}"; do
    name=${tag%%=*}
    val=${tag#*=}
    case $name in
      "$TAGNAME")
        [[ $val == "$key" ]] || {
          err "== FAILED validating LVM tags =="
          err
          err "LVM tag: $tag"
          err
          err "ceph auth print-key $kname:"
          err "$key"
          err
          die "Keys need to be in sync to start"
        }
        tags=''
        ;;
      ceph.osd_fsid)
        [[ $val == "$fsid" ]] || {
          err "== FAILED LVM tag $name appears invalid"
          err "  value: $val"
          die "  fsid: $fsid"
        }
        ;;
      ceph.cluster_fsid)
        [[ $val == "$FSID" ]] || {
          err "== FAILED LVM tag $name appears invalid"
          err "  value: $val"
          die "  ceph fsid: $FSID"
        }
        ;;
      ceph.osd_id)
        [[ $val == "$id" ]] || {
          err "== FAILED LVM tag $name appears invalid"
          err "  value: $val"
          die "  osd id: $id"
        }
        ;;
      ceph.encrypted)
        [[ $val == 1 ]] || {
          err "== FAILED LVM tag $name appears invalid"
          err "  value: $val"
          die "  expected: 1"
        }
        ;;
    esac
  done
  [[ $tags ]] && die "Unable to locate LVM tag $TAGNAME"
  echo " - LVM tag $TAGNAME present and matches"

  # check that lockbox.keyring allows access to the luks key
  luks=$(ceph 2>/dev/null --keyring lockbox.keyring \
              --name "client.osd-lockbox.$fsid" \
              config-key get "dm-crypt/osd/$fsid/luks")
  [[ $luks ]] || {
    err "== FAILED to access luks key with lockbox.keyring =="
    err "  ceph auth name: client.osd-lockbox.$fsid"
    err "  luks config-key: dm-crypt/osd/$fsid/luks"
    err
    die "Check that caps on the lockbox.keyring are correct for the OSD!"
  }
  [[ ${#key} == 60 ]] && {
    echo "Everythings looks ok for OSD $id"
    popd >/dev/null || die "popd failed!"
    continue
  }

  # we're ready to rotate keys...
  echo
  echo "ACTION: Checking if safe to stop OSD $id"
  status=$(ceph osd ok-to-stop "osd.$id")
  [[ $status ]] || die "ceph osd ok-to-stop failed for OSD $id"
  [[ $(echo "$status" | jq -r '.ok_to_stop') == "true" ]] || {
    err "OSD $id not ok-to-stop"
    err "PGS not OK: $(echo "$status" | jq -r '.num_not_ok_pkgs')"
    die "Try again later..."
  }

  echo "OSD ok to stop!  Stopping..."
  pause
  $debug ceph orch daemon stop "osd.$id"
  echo "Waiting for OSD to stop..."
  pstatus=''
  for (( x=0; x<20; x++ )); do
    status=$(ceph orch ps --daemon_type osd --daemon_id "$id" --format json |
               jq -r '.[0].status_desc')
    [[ $debug ]] && status=stopped
    [[ $status != "$pstatus" ]] && echo "OSD status now $status"
    pstatus=$status
    [[ $status == stopped ]] && break
    [[ $status == error ]] &&
      die "OSD $id has failed... manually check what's wrong!"
    sleep 5
  done
  [[ $status == stopped ]] || die "Timed out waiting for OSD $id to stop! (status: $status)"
  echo "  OSD stopped!"

  # Now the fun part... rotating the lockbox key!"
  echo
  echo "ACTION: rotating key $kname..."
  pause
  $debug ceph auth rotate "$kname"

  # get new key and keyring
  newkey=$(ceph auth print-key "$kname")
  [[ $key == "$newkey" ]] && {
    [[ $debug ]] || die "Failed to rotate key, key remains $key"
  }
  nkr=$(ceph auth get "$kname" | grep -v "caps ")
  [[ $nkr ]] || die "Unable to retrieve new lockbox.keyring"

  # finally, update the tags/files
  echo "ACTION: updating LVM tags on $lvpath..."
  pause
  $debug lvchange --deltag "ceph.cephx_lockbox_secret=$key" "$lvpath"
  $debug lvchange --addtag "ceph.cephx_lockbox_secret=$newkey" "$lvpath"

  echo "ACTION: updating lockbox.keyring..."
  pause
  if [[ $debug ]]; then
    echo "$nkr"
  else
    echo "$nkr" > lockbox.keyring
  fi
  $debug chmod 600 lockbox.keyring
  $debug chown ceph:ceph lockbox.keyring

  # re-check that the new key allows access to the luks key
  luks=$(ceph 2>/dev/null --keyring lockbox.keyring \
              --name "client.osd-lockbox.$fsid" \
              config-key get "dm-crypt/osd/$fsid/luks")
  [[ $luks ]] || {
    err "== FAILURE to access luks config-key with new lockbox.keyring =="
    err "  ceph auth name: client.osd-lockbox.$fsid"
    err "  luks config-key: dm-crypt/osd/$fsid/luks"
    err
    err "Original key for ref:"
    err "$lb"
    err
    die "Check that caps on the lockbox.keyring are correct for the OSD!"
  }
  echo "New key allows access to the luks config-key!"

  echo
  echo "Now ready to restart OSD $id"
  pause
  $debug ceph orch daemon start "osd.$id"

  echo "Waiting for OSD $id to start..."
  pstatus=''
  for (( x=0; x<20; x++ )); do
    status=$(ceph orch ps --daemon_type osd --daemon_id "$id" --format json |
               jq -r '.[0].status_desc')
    [[ $status != "$pstatus" ]] && echo "  OSD status now $status"
    pstatus=$status
    [[ $status == running ]] && break
    [[ $status == error ]] &&
      die "OSD $id has failed... manually check what's wrong!"
    [[ $debug ]] && {
      status=running
      break
    }
    sleep 5
  done
  [[ $status == running ]] || die "Timed out waiting for OSD $id to start! (status: $status)"

  echo
  echo "Checking ceph status..."
  pstatus=''
  for (( x=0; x<20; x++ )); do
    status=$(ceph status --format json | jq -r '.health.status')
    [[ $status == "$pstatus" ]] || echo "  Status now: $status"
    pstatus=$status
    [[ $status == "HEALTH_OK" ]] && break
    sleep 5
  done
  [[ $status == "HEALTH_OK" ]] || die "Timed out waiting for ceph HEALTHY"

  echo
  echo "=== CONGRATULATIONS! ==="
  echo "OSD $id has had it's keys rotated!"
  echo
  popd >/dev/null || die "popd failed!"
done

echo "Finished!"
