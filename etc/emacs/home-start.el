;;; Site wide settings for all users   -*- lexical-binding:t -*-

;; PREFIX myhome- used for hooks.

;; Copy/link to /usr/local/share/emacs/site-lisp/site-start.d
;;  (or /etc/emacs/site-start.d/99home-start.el)
;;
;; Identify what parts of your `.emacs' take so long. You can do
;; this e.g. by starting emacs with "emacs -q", set up your
;; load-path, and then evaluate
;;
;; (benchmark-run
;;   (require 'package))
;;
;; The first number appearing in the echo area will be the time needed to run
;; that command.
;;
;; Use autoloads, which delay the loading of the complete package until one of
;; the interactive functions is used.
;;
;; If you want to set options which need to be evaluated after a package is
;; loaded, you can use `eval-after-load'.

;; Source for good .emacs http://www.mygooglest.com/fni/dot-emacs.html
;; XXX Go and see http://stackoverflow.com/questions/298065/which-are-the-gnu-emacs-modes-extensions-you-cant-live-without

;; Still need to put this in personal .emacs for it to work
;(setq inhibit-splash-screen t)
(setcdr command-line-args (cons "--no-splash" (cdr command-line-args)))

;; don't truncate the message log buffer when it becomes large
(setq message-log-max t)

;; add ~/.emacs.d/lisp to path
(when (boundp 'user-emacs-directory)
  (let ((my-directory
         (concat user-emacs-directory "lisp")))
    (when (file-directory-p my-directory)
      (add-to-list 'load-path my-directory))))

(when (file-directory-p "/usr/local/share/emacs/site-lisp")
  (add-to-list 'load-path "/usr/local/share/emacs/site-lisp"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Try Require

(defvar missing-packages-list nil
  "List of packages that `try-require' can't find.")

;; attempt to load a feature/library, failing silently
(defun try-require (feature)
  "Attempt to load a library or module. Return true if the
library given as argument is successfully loaded. If not, instead
of an error, just add the package to a list of missing packages."
  (condition-case err
      ;; protected form
      (progn
        (message "Checking for library `%s'..." feature)
        (if (stringp feature)
            (load-library feature)
          (require feature))
        (message "Checking for library `%s'... Found" feature))
    ;; error handler
    (file-error  ; condition
     (progn
       (message "Checking for library `%s'... Missing" feature)
       (add-to-list 'missing-packages-list feature 'append))
     nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Gnu Emacs (not XEmacs)

(defmacro GNUEmacs (&rest body)
  "Execute any number of forms if running under GNU Emacs."
  (list 'if (string-match "GNU Emacs" (version))
        (cons 'progn body)))

(GNUEmacs
 (transient-mark-mode 1)
 (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
 (when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
 ;; make loaded files give a message
 (setq force-load-messages t)
 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; XEmacs

(defmacro XEmacs (&rest body)
  "Execute any number of forms if running under XEmacs."
  (list 'if (string-match "XEmacs" (version))
        (cons 'progn body)))

(XEmacs
 ;; don't offer migration of the init file
 (setq load-home-init-file t)
 (setq modeline-3d-p nil)
 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; XLaunch

(defmacro XLaunch (&rest body)
  "Execute any number of forms if running under X Windows."
  (list 'if (eq window-system 'x)(cons 'progn body)))

(XLaunch
 (setq modeline-3d-p nil)
 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TextLaunch

(defmacro TextLaunch (&rest body)
  "Execute any number of forms if running in text mode."
  (list 'if (eq window-system nil)(cons 'progn body)))

(TextLaunch
 (menu-bar-mode 0)
 (setq tool-bar-mode nil)
 (setq toolbar-visible-p nil)
 (if (not (boundp 'image-types)) (defvar image-types nil))
 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Features

;; (setq display-time-mail-file t)
(setq line-number-mode t)
(setq mumamo-chunk-coloring 10)
;; don't add newlines to end of buffer when scrolling
(setq next-line-add-newlines nil)
;; ignore case when reading a file name completion
(setq read-file-name-completion-ignore-case t)
;; ignore case when reading a buffer name
(setq read-buffer-completion-ignore-case t)
;; do not consider case significant in completion (GNU Emacs default)
(setq completion-ignore-case t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Apropos

;; You can ask what pertains to a given topic by typing
;; `M-x apropos RET pattern RET'

;; check all variables and non-interactive functions as well
(setq apropos-do-all t)

;; add apropos help about variables (bind `C-h A' to `apropos-variable')
(GNUEmacs
 (define-key help-map (kbd "A") 'apropos-variable))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Time

;; (setq display-time-form-list (quote (date time)))
(if (fboundp 'display-time)
    (progn
      (setq display-time-string-forms '(12-hours ":" minutes am-pm))
      (display-time)
      ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Added Functions

(defun myhome-display-other-window (n) "Switch to other window and kill others"
       (interactive "p")
       (other-window n)
       (delete-other-windows))

(defun myhome-list-colors (&optional list)
  "Modified `list-colors-display' showing color aliases."
  (interactive)
  (when (and (null list) (> (display-color-cells) 0))
    (setq list (mapcar 'car color-name-rgb-alist))
    (when (memq (display-visual-class) '(gray-scale pseudo-color direct-color))
      ;; Don't show more than what the display can handle.
      (let ((lc (nthcdr (1- (display-color-cells)) list)))
        (if lc
            (setcdr lc nil)))))
  (with-output-to-temp-buffer "*MYColors*"
    (save-excursion
      (set-buffer standard-output)
      (let (s)
        (while list
          (setq s (point))
          (insert (car list))
          (indent-to 20)
          (put-text-property s (point) 'face
                             (cons 'background-color (car list)))
          (setq s (point))
          (insert "  " (car list)
                  (if  window-system ""
                    (concat " ("(car  (tty-color-desc (car list))) ")") ) "\n")
          (put-text-property s (point) 'face
                             (cons 'foreground-color (car list)))
          (setq list (cdr list)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Added Keys

;; for my custom functions
(global-set-key (kbd "C-x 4 o") 'myhome-display-other-window)

;; XEmacs default for moving point to a given line number
(GNUEmacs
 (global-set-key (kbd "M-g") 'goto-line))

(global-set-key (kbd "M-G") 'what-line)
(global-set-key (kbd "C-c C-f") 'set-fill-column)
(global-set-key (kbd "C-c f") 'auto-fill-mode)
(global-set-key (kbd "C-c g") 'goto-line)
(global-set-key (kbd "C-c s") 'shell)
(global-set-key (kbd "C-x C-m") 'compile)
(global-set-key (kbd "<f11>") 'indent-region)
(global-set-key (kbd "<f12>") 'help)
(global-set-key (kbd "<M-backspace>") 'backward-kill-word)

(global-set-key (kbd "M-r") 'replace-string)
(global-set-key (kbd "M-g") 'fill-paragraph)

(global-set-key (kbd "<home>") 'beginning-of-buffer)
(global-set-key (kbd "<end>") 'end-of-buffer)

(global-set-key (kbd "C-M-_") 'dabbrev-completion)

;; DEL key
(setq delete-key-deletes-forward t)
;;(keyboard-translate ?\C-h ?\C-?)
;;(keyboard-translate ?\C-? ?\C-h)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Defaults

(setq fill-column 75)
(setq standard-indent 2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Paren Mode

(when (try-require 'paren)
  (GNUEmacs
   (show-paren-mode t))
  (XEmacs
   (paren-set-mode 'paren))
  (setq show-paren-delay 0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lisp Mode

(defun myhome-text-mode-hook ()
  "Hook to setup defaults in Text mode"
  (interactive)
  (auto-fill-mode 1)
  )

(add-hook 'text-mode-hook 'myhome-text-mode-hook t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lisp Mode

(defun myhome-emacs-lisp-mode-hook ()
  "Hook to setup defaults in Emacs Lisp mode"
  (interactive)
  (eldoc-mode)
  ;; Use spaces, not tabs.
  (setq indent-tabs-mode nil)
  ;; Pretty-print eval'd expressions.
  (define-key emacs-lisp-mode-map
    "\C-x\C-e" 'pp-eval-last-sexp)
  ;; (define-key emacs-lisp-mode-map
  ;;  "\r" 'reindent-then-newline-and-indent)
  )

(add-hook 'emacs-lisp-mode-hook 'myhome-emacs-lisp-mode-hook t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; C Mode

(add-to-list 'auto-mode-alist '("\\.pc\\'" . c-mode) t)
(add-to-list 'auto-mode-alist '("\\.module\\'" . c-mode) t)

(defun myhome-justify-c-comment () "move a C comment to right margin"
       (interactive)
       (save-excursion
         (end-of-line)
         (search-backward "/*")
         (delete-horizontal-space)
         (end-of-line)
         (setq addn (- 79 (current-column)))
         (search-backward "/*")
         (while (> addn 0)
           (insert ? )
           (setq addn (1- addn)))))

(defun myhome-c-mode-common-hook ()
  "Hook to setup defaults in C-like modes"
  (interactive)
  (setq show-trailing-whitespace t)
  (local-set-key "\C-t" 'myhome-justify-c-comment)
  ;;(setq indent-tabs-mode nil)
  ;;(setq c-basic-offset 8)
  ;; no tabs, 2 chars
  (c-set-style "gnu")
  ;; no tabs, 5 chars
  ;;(c-set-style "K&R")
  ;; tab indent, 8 chars
  ;;(c-set-style "python")
  ;; guess indentation...
  (c-guess)
  )
(add-hook 'c-mode-common-hook 'myhome-c-mode-common-hook t)
;; not in hook so can override
(setq c-guess-region-max 5000)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Java Mode

(defun myhome-java-mode-hook ()
  "Hook to setup defaults in Java mode"
  (interactive)
  (setq indent-tabs-mode t)
  (setq c-basic-offset 8)
  (setq show-trailing-whitespace t)
  )

(add-hook 'java-mode-hook 'myhome-java-mode-hook t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HTML Mode

;;(setq mumamo-chunk-coloring 10)

(add-to-list 'auto-mode-alist '("\\.xml\\'" . html-mode) t)

(defun myhome-html-mode-hook ()
  "Hook to setup defaults in HTML mode"
  (interactive)
  (setq sgml-basic-offset 4)
  (setq indent-tabs-mode t)
  (setq show-trailing-whitespace t)
  )

(add-hook 'html-mode-hook 'myhome-html-mode-hook t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CSS Mode

(defun myhome-css-mode-hook ()
  "Hook to setup defaults in CSS mode"
  (interactive)
  (setq css-indent-offset 2)
  )

(add-hook 'css-mode-hook 'myhome-css-mode-hook t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Javascript Mode

(defun myhome-js-mode-hook ()
  "Hook to setup defaults in JS mode"
  (interactive)
  (setq js-indent-level 2)
  )

(add-hook 'js-mode-hook 'myhome-js-mode-hook t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sh Mode (editing shell scripts)

(defun myhome-sh-mode-hook ()
  "Hook to setup defaults in Shell mode"
  (interactive)
  (setq sh-indentation 2)
  (setq sh-basic-offset 2)
  (setq indent-tabs-mode nil)
  (setq show-trailing-whitespace t)
  )

(add-hook 'sh-mode-hook 'myhome-sh-mode-hook t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Conf Mode

;; add httpd .inc files
(add-to-list 'auto-mode-alist '("\\.inc\\'" . conf-space-mode) t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Font Lock

;; make buffer size irrelevant for fontification
(setq font-lock-maximum-size nil)

(XEmacs
 ;; stop showing that annoying progress bar when fontifying
 (setq progress-feedback-use-echo-area nil)
 ;; enable Font Lock mode
 ;; (font-lock-mode)
 )

;;(turn-on-font-lock)

(if (fboundp 'global-font-lock-mode)
    (global-font-lock-mode 1)        ; GNU Emacs
  (setq font-lock-auto-fontify t))   ; XEmacs

(setq font-lock-maximum-decoration
      '((c-mode . t) (c++-mode . t) (t . 1)))
(tty-suppress-bold-inverse-default-colors t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Default Params

(setq diff-switches "-u")
(setq compile-command "make ")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Backups

;; call this function to enable homedir backups
(defun use-homedir-backups ()
  "Use directories under ~/.emacs.d for autosave and backups"
  (interactive)
  ;; create the autosave/backups dirs if necessary, since emacs won't.
  (make-directory "~/.emacs.d/autosaves/" t)
  (make-directory "~/.emacs.d/backups/" t)
  ;; Put autosave files (ie #foo#) and backup files (ie foo~) in ~/.emacs.d/.
  (setq auto-save-file-name-transforms (quote ((".*" "~/.emacs.d/autosaves/" t))))
  ;; keep hard links on orig files
  (setq backup-by-copying-when-linked t)
  (setq backup-directory-alist (quote (("." . "~/.emacs.d/backups/")))))

;; enable it
(use-homedir-backups)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Default Theme

(if (and (boundp 'custom-theme-load-path)
         (file-readable-p "/usr/local/share/emacs/site-lisp/themes/home-dark-theme.el"))
    (progn (add-to-list 'custom-theme-load-path "/usr/local/share/emacs/site-lisp/themes")
           (load-theme 'home-dark t))
  ;; fallback
  (custom-set-faces
   '(default ((t (:foreground "snow" :background "black"))))
   '(mode-line ((t (:foreground "snow" :background "midnightblue"))))
   '(modeline-mousable ((t (:foreground "red" :background "midnightblue"))) t)
   '(show-paren-match ((((class color)) (:background "DarkOliveGreen"))))))

;; disable italic/oblique in all faces
(defun my/deitalic (&optional faces)
  "Set the slant (italic/oblique) property of FACES to `normal'.
If FACES is not provided or nil, use `face-list' instead."
  (interactive)
  (mapc (lambda (face)
          (when (member (face-attribute face :slant) '(italic oblique))
            (set-face-attribute face nil :slant 'normal)))
        (or faces (face-list))))
(my/deitalic)

;; dont use underline for italic if font doesn't support it.
(set-face-attribute 'italic nil :underline nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Terminal tweaks

(defun myhome-linux-init ()
  "Setup extra keys for linux console"
  (global-set-key "\e[1;5A" [C-up])
  (global-set-key "\e[1;5B" [C-down])
  )

(defun myhome-xterm-init ()
  "Setup Meta cursor keys for xterm"
  (global-set-key "\e[1;9A" [M-up])
  (global-set-key "\e[1;9B" [M-down])
  (global-set-key "\e[1;9C" [M-right])
  (global-set-key "\e[1;9D" [M-left])
  (global-set-key "\e[1;9F" [M-end])
  (global-set-key "\e[1;9H" [M-home])

  (global-set-key "\e[1;10A" [M-S-up])
  (global-set-key "\e[1;10B" [M-S-down])
  (global-set-key "\e[1;10C" [M-S-right])
  (global-set-key "\e[1;10D" [M-S-left])
  (global-set-key "\e[1;10F" [M-S-end])
  (global-set-key "\e[1;10H" [M-S-home])

  (global-set-key "\e[1;13A" [M-C-up])
  (global-set-key "\e[1;13B" [M-C-down])
  (global-set-key "\e[1;13C" [M-C-right])
  (global-set-key "\e[1;13D" [M-C-left])
  (global-set-key "\e[1;13F" [M-C-end])
  (global-set-key "\e[1;13H" [M-C-home])

  (global-set-key "\e[1;14A" [M-S-C-up])
  (global-set-key "\e[1;14B" [M-S-C-down])
  (global-set-key "\e[1;14C" [M-S-C-right])
  (global-set-key "\e[1;14D" [M-S-C-left])
  (global-set-key "\e[1;14F" [M-S-C-end])
  (global-set-key "\e[1;14H" [M-S-C-home])
  )

(defun myhome-screen-init ()
  "Setup screen like xterm"
  (try-require "term/xterm")
  (when (fboundp 'terminal-init-xterm)
    (terminal-init-xterm)
    (myhome-xterm-init)
    ))

(defun myhome-tty-setup-hook ()
  "Hook to setup tty modes"
  (interactive)
  (let ((term (if (fboundp 'tty-type)
                 (tty-type (selected-frame))
               (getenv "TERM" (selected-frame)))))
    (if (string-equal "linux" term) (myhome-linux-init))
    (if (string-match "xterm.*" term) (myhome-xterm-init))
    (if (string-match "screen.*" term) (myhome-screen-init))
    ))
(add-hook 'tty-setup-hook 'myhome-tty-setup-hook t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Server for shell aliases

;; Start server so shell commands can talk to emacs
(when (and (fboundp 'server-start)
           (not (zerop (length (getenv-internal "MYEC_SERVER_NAME")))))
  (setq server-name (getenv-internal "MYEC_SERVER_NAME"))
  (server-start))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; External packages

;; Use secure connection to ELPA
(customize-set-variable 'package-archives
                        '(("gnu" . "https://elpa.gnu.org/packages/")
                          ("melpa" . "https://stable.melpa.org/packages/")))

;; Re-init with updated package-directory-list
(when (version< emacs-version "27.0")
  (when (fboundp 'package-initialize) (package-initialize)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Xterm Color (MELPA package)
;;
(when (fboundp 'xterm-color-filter)
  (setq comint-terminfo-terminal "xterm-256color")
  (setq comint-output-filter-functions
        (remove 'ansi-color-process-output comint-output-filter-functions))
  ;; these are colors used by xterm...
  (setq xterm-color-names
        ["#000000" "#CD0000" "#00CD00" "#CDCD00" "#0000EE" "#CD00CD" "#00CDCD" "#E5E5E5"])
  (setq xterm-color-names-bright
        ["#7F7F7F" "#FF0000" "#00FF00" "#FFFF00" "#5C5CFF" "#FF00FF" "#00FFFF" "#FFFFFF"])
  (add-hook 'shell-mode-hook
            (lambda ()
              ;; Disable font-locking in this buffer to improve performance
              (font-lock-mode -1)
              ;; Prevent font-locking from being re-enabled in this buffer
              (make-local-variable 'font-lock-function)
              (setq font-lock-function (lambda (_) nil))
              (add-hook 'comint-preoutput-filter-functions 'xterm-color-filter nil t)))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bash Complete (MELPA package)
;; bash-completion for <tab> complete in shell-mode

(when (fboundp 'bash-completion-dynamic-complete)
  (add-hook 'shell-dynamic-complete-functions
            'bash-completion-dynamic-complete))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Web Mode (MELPA package)

(when (fboundp 'web-mode)
  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.[agj]sp\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.php\\'" . web-mode))
  )

(defun myhome-web-mode-common-hook ()
  "Hook to setup defaults in Web modes"
  (interactive)
  ;; no tabs
  ;;(setq indent-tabs-mode nil)
  (setq web-mode-code-indent-offset 8)
  )
(add-hook 'web-mode-hook 'myhome-web-mode-common-hook t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Magit (MELPA package)
(when (fboundp 'magit-status)
  (global-set-key (kbd "C-x g") 'magit-status)
  )
;; Local Variables:
;; indent-tabs-mode: nil
;; tab-width: 2
;; End:
