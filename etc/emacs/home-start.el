;;; Site wide settings for all users   -*- lexical-binding:t -*-

;; Copy/link to /usr/local/share/emacs/site-lisp/site-start.d
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

;; don't truncate the message log buffer when it becomes large
(setq message-log-max t)

(when (file-directory-p "~/.emacs.d/site-lisp")
  (add-to-list 'load-path "~/.emacs.d/site-lisp"))

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
 (defadvice load (before debug-log activate)
   (message "Loading %s..." (locate-library (ad-get-arg 0))))
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
;; X Mode

(defmacro XLaunch (&rest body)
  "Execute any number of forms if running under X Windows."
  (list 'if (eq window-system 'x)(cons 'progn body)))

(XLaunch
 (setq modeline-3d-p nil)
 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Text Mode

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
;; Paren Mode

(when (try-require 'paren)
  (GNUEmacs
   (show-paren-mode t))
  (XEmacs
   (paren-set-mode 'paren)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Added Function

(defun switch-display-other-window (n) "Switch to other window and kill others"
       (interactive "p")
       (other-window n)
       (delete-other-windows))

(defun justify-c-comment () "move a C comment to right margin"
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

(defun my-list-colors-display (&optional list)
  "Modified `list-colors-display'."
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
(global-set-key "\C-x4o" 'switch-display-other-window)
(global-set-key "\C-t" 'justify-c-comment)

;; XEmacs default for moving point to a given line number
(GNUEmacs
 (global-set-key (kbd "M-g") 'goto-line))

(global-set-key (kbd "M-G") 'what-line)
(global-set-key "\C-c\C-f" 'set-fill-column)
(global-set-key "\C-cf" 'auto-fill-mode)
(global-set-key "\C-cg" 'goto-line)
(global-set-key "\C-cd" 'my-from-dos)
(global-set-key "\C-cs" 'shell)
(global-set-key "\C-x\C-m" 'compile)
(global-set-key [f11] 'indent-region)
(global-set-key [f12] 'help)
(global-set-key [(meta backspace)] 'backward-kill-word)

(global-set-key [(meta r)] 'replace-string)
(global-set-key [(meta g)] 'fill-paragraph)

(global-set-key [(home)] 'beginning-of-buffer)
(global-set-key [(end)] 'end-of-buffer)

(global-set-key [(control meta _)] 'dabbrev-completion)

;; DEL key
(setq delete-key-deletes-forward t)
;;(keyboard-translate ?\C-h ?\C-?)
;;(keyboard-translate ?\C-? ?\C-h)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Scroll Wheel

(cond
 ((boundp 'mouse-wheel-mode) (mouse-wheel-mode 1))
 (t (setq my-scroll-interval 5)
    (defun my-scroll-down-some-lines ()
      (interactive)
      (scroll-down my-scroll-interval))
    (defun my-scroll-up-some-lines ()
      (interactive)
      (scroll-up my-scroll-interval))
    (global-set-key [(mouse-4)] 'my-scroll-down-some-lines)
    (global-set-key [(mouse-5)] 'my-scroll-up-some-lines)
    (define-key global-map [(button4)] 'my-scroll-down-some-lines)
    (define-key global-map [(button5)] 'my-scroll-up-some-lines))
 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Defaults

(setq fill-column 75)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GIT

(defadvice vc-dir-prepare-status-buffer (before my-vcs-goto-top-directory activate compile)
  (let* ((backend (ad-get-arg 2))
         (vcs-dir (ad-get-arg 1))
         (vcs-top-dir (vc-call-backend backend 'responsible-p vcs-dir)))
    (when (stringp vcs-top-dir)
      (ad-set-arg 1 vcs-top-dir))))

(let ((git-el "/usr/share/doc/git-core-doc/contrib/emacs"))
  (when (file-directory-p git-el)
    (add-to-list 'load-path git-el)
    (autoload 'git-blame-mode "git-blame" "Minor mode for incremental blame for Git." t)
    (autoload 'git-status "git" "Entry point into git-status mode." t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lisp Mode

(defun my-text-mode-hook ()
  "Hook to setup defaults in Text mode"
  (interactive)
  (auto-fill-mode 1)
  )

(add-hook 'text-mode-hook 'my-text-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lisp Mode

(defun my-emacs-lisp-mode-hook ()
  "Hook to setup defaults in Emacs Lisp mode"
  (interactive)
  ;; Use spaces, not tabs.
  (setq indent-tabs-mode nil)
  ;; Pretty-print eval'd expressions.
  (define-key emacs-lisp-mode-map
    "\C-x\C-e" 'pp-eval-last-sexp)
  ;;(define-key emacs-lisp-mode-map
  ;;  "\r" 'reindent-then-newline-and-indent))
  )

(add-hook 'emacs-lisp-mode-hook 'my-emacs-lisp-mode-hook)
(add-hook 'emacs-lisp-mode-hook 'eldoc-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; C Mode

(add-to-list 'auto-mode-alist '("\\.pc\\'" . c-mode) t)
(add-to-list 'auto-mode-alist '("\\.module\\'" . c-mode) t)

(defun my-c-mode-common-hook ()
  "Hook to setup defaults in C-like modes"
  (interactive)
  (setq show-trailing-whitespace t)
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
(setq c-guess-region-max 5000)
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Java Mode

(defun my-java-mode-hook ()
  "Hook to setup defaults in Java mode"
  (interactive)
  (setq indent-tabs-mode t)
  (setq c-basic-offset 8)
  (setq show-trailing-whitespace t)
  )

(add-hook 'java-mode-hook 'my-java-mode-hook)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HTML Mode

;;(setq mumamo-chunk-coloring 10)

(add-to-list 'auto-mode-alist '("\\.xml\\'" . html-mode) t)

(defun my-html-mode-hook ()
  "Hook to setup defaults in HTML mode"
  (interactive)
  (setq sgml-basic-offset 4)
  (setq indent-tabs-mode t)
  (setq show-trailing-whitespace t)
  )

(add-hook 'html-mode-hook 'my-html-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CSS Mode

(defun my-css-mode-hook ()
  "Hook to setup defaults in CSS mode"
  (interactive)
  (setq css-indent-offset 2)
  )

(add-hook 'css-mode-hook 'my-css-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Javascript Mode

(defun my-js-mode-hook ()
  "Hook to setup defaults in JS mode"
  (interactive)
  (setq js-indent-level 2)
  )

(add-hook 'js-mode-hook 'my-js-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Shell Mode

(defun my-sh-mode-hook ()
  "Hook to setup defaults in Shell mode"
  (interactive)
  (setq sh-indentation 2)
  (setq sh-basic-offset 2)
  (setq indent-tabs-mode nil)
  (setq show-trailing-whitespace t)
  )

(add-hook 'sh-mode-hook 'my-sh-mode-hook)

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
 ;;(font-lock-mode))
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

(defun add-xterm-meta-cursors ()
  "Meta cursor keys for xterm."
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

(defun my-term-setup-hook ()
  "Hook for default terminal setup"
  (interactive)
  (when (fboundp 'terminal-init-xterm)
    (add-xterm-meta-cursors))
  (when (and (fboundp 'terminal-init-screen)
             (boundp 'xterm-function-map))
    ;; merge xterm-function-map
    (let ((map (copy-keymap xterm-function-map)))
      (set-keymap-parent map (keymap-parent input-decode-map))
      (set-keymap-parent input-decode-map map)))
  )

;;(add-hook 'term-setup-hook 'my-term-setup-hook)

(defun terminal-init-screen ()
  "Terminal initialization function for screen."
  ;; Use the xterm initialization code.
  (try-require "term/xterm")
  (when (fboundp 'terminal-init-xterm)
    (terminal-init-xterm))
  )

(defun terminal-init-screen.xterm ()
  "Terminal initialization function for screen.xterm."
  ;; Use the xterm initialization code.
  (terminal-init-screen)
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Server for shell aliases

;; Start server so shell commands can talk to emacs
(when (and (fboundp 'server-start)
           (not (zerop (length (getenv-internal "MYEC_SERVER_NAME")))))
  (setq server-name (getenv-internal "MYEC_SERVER_NAME"))
  (server-start)
  ;; export socket-dir to shells
  (if (not server-use-tcp)
      (setenv "MYEC_SERVER_SOCKDIR" server-socket-dir)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; External packages

;; Use secure connection to ELPA
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://stable.melpa.org/packages/")))

;; Re-init with updated package-directory-list
(when (fboundp 'package-initialize) (package-initialize))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Web Mode (ELPA package, package-initialize first)

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

(defun my-web-mode-common-hook ()
  "Hook to setup defaults in Web modes"
  (interactive)
  ;; no tabs
  ;;(setq indent-tabs-mode nil)
  (setq web-mode-code-indent-offset 8)
  )
(add-hook 'web-mode-hook 'my-web-mode-common-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Magit (ELPA package, package-initialize first)
(when (fboundp 'magit-status)
  (global-set-key (kbd "C-x g") 'magit-status)
  )
;; Local Variables:
;; indent-tabs-mode: nil
;; tab-width: 2
;; End:
