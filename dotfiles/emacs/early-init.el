;;; -*- lexical-binding: t; -*-

;; optimizations
(defvar eglot-server-programs ())
(defvar native-comp-deferred-compilation-deny-list ())
(setq native-comp-jit-compilation t)
(setq package-enable-at-startup nil)
(setq frame-inhibit-implied-resize t)
(setq use-dialog-box nil)

;; remove ugly early
(menu-bar-mode -1)
(unless (and (display-graphic-p) (eq system-type 'darwin))
  (push '(menu-bar-lines . 0) default-frame-alist))
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; max memory available for gc on startup
(setq gc-cons-threshold most-positive-fixnum)

;; garbage collect when not focused
(add-function :after
                  after-focus-change-function
                  (lambda () (unless (frame-focus-state) (garbage-collect))))

;; file name handler disable
(defvar me/-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist me/-file-name-handler-alist)))

;; more speed
(setq site-run-file nil)
(setq inhibit-compacting-font-caches t)
(when (boundp 'read-process-output-max)
  ;; 1MB in bytes, default 4096 bytes
  (setq read-process-output-max 1048576))

;; straight
(setq straight-cache-autoloads t
      straight-vc-git-default-clone-depth 1
      vc-follow-symlinks t)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
(require 'straight-x)
(straight-use-package 'use-package)

(use-package benchmark-init
  :demand t
  :straight (:host github :repo "kekeimiku/benchmark-init-el")
  :hook (after-init . benchmark-init/deactivate))

(use-package gcmh
  :straight t
  :demand t
  :config
  (gcmh-mode 1))

(setq byte-compile-warnings '(not nresolved
                                  free-vars
                                  callargs
                                  rdefine
                                  obsolete
                                  noruntime
                                  cl-functions
                                  interactive-only))

(setq screen-font "Monospace:size=34")
(setq-default default-frame-alist
              (append (list
                       `(font . ,screen-font)
                       '(internal-border-width . 0)
                       '(left-fringe    . 0)
                       '(right-fringe   . 0)
                       '(tool-bar-lines . 0)
                       '(menu-bar-lines . 0)
                       '(vertical-scroll-bars . nil))))

(setq visible-bell nil
      ring-bell-function #'ignore)

(setq-default auto-save-default nil
              auto-save-file-name-transforms `((".*" ,temporary-file-directory t))
              backup-by-copying t
              backup-directory-alist `((".*" . ,temporary-file-directory))
              c-nonexistent-file-or-buffer nil
              delete-old-versions t
              dired-recursive-copies 'always
              dired-recursive-deletes 'always
              dired-clean-confirm-killing-deleted-buffers nil
              fill-column 100
              undo-limit 250000
              native-comp-async-report-warnings-errors nil
              inhibit-startup-echo-area-message t
              make-backup-files nil
              auto-save-default nil
              jit-lock-defer-time 0
              fast-but-imprecise-scrolling t
              make-backup-files nil
              scroll-conservatively 101
              scroll-preserve-screen-position t
              tab-width 4
              org-enforce-todo-dependencies t
              truncate-lines t
              split-width-threshold nil
              inhibit-startup-screen t
              initial-scratch-message nil
              create-lockfiles nil)

(setq kill-buffer-query-functions
      (remq 'process-kill-buffer-query-function
            kill-buffer-query-functions))
(setq-default indent-tabs-mode nil)
(fset 'yes-or-no-p 'y-or-n-p)

(defalias 'yes-or-no-p 'y-or-n-p)
(customize-set-variable 'scroll-bar-mode nil)
(customize-set-variable 'horizontal-scroll-bar-mode nil)

(global-font-lock-mode 1)
(column-number-mode 1)
(winner-mode 1)
(menu-bar-mode -1)
(toggle-scroll-bar -1)
(tool-bar-mode -1)
(blink-cursor-mode -1)
(save-place-mode 1)
(recentf-mode 1)

(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))

(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

(add-to-list 'display-buffer-alist
             (cons "\\*Async Shell Command\\*.*" (cons #'display-buffer-no-window nil)))

(put 'dired-find-alternate-file 'disabled nil)

(add-to-list 'auto-mode-alist '("\\.bin\\'" . hexl-mode))
(add-to-list 'auto-mode-alist '("\\.gb\\'" . hexl-mode))
(add-to-list 'auto-mode-alist '("\\.ch8\\'" . hexl-mode))

;; utf-8
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-locale-environment "en_NZ.UTF-8")
(setq-default buffer-file-coding-system 'utf-8)
(when (boundp 'default-buffer-file-coding-system)
  (setq default-buffer-file-coding-system 'utf-8))
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

;; electric pair
;; (add-hook 'prog-mode-hook 'electric-pair-mode)

;; lisp
(add-hook 'elisp-lisp-mode-hook
          (lambda () (add-hook 'local-write-file-hooks 'check-parens)))

;; tramp
(setq remote-file-name-inhibit-cache nil)
(setq vc-ignore-dir-regexp
      (format "%s\\|%s"
              vc-ignore-dir-regexp
              tramp-file-name-regexp))
(setq tramp-inline-compress-start-size 1000)
(setq tramp-copy-size-limit 10000)
(setq vc-handled-backends '(Git))
(setq tramp-default-method "scp")
(setq tramp-use-ssh-controlmaster-options nil)
(setq tramp-verbose 1)

;; handle long lines
(global-so-long-mode t)

;; faster paren
(setq show-paren-delay 0.0)

;; modeline
;; (setq-default mode-line-format
;;               (list
;;                '(:eval (propertize " %b" 'face (buffer-file-name)))
;;                '(:eval (propertize " (%l:%c)" 'face (buffer-file-name)))))

;; Update mode-line-format to conditionally display the clocked time if an Org mode clock is running
(setq-default mode-line-format
              (list
               ;; Display the buffer name
               '(:eval (propertize " %b" 'face (buffer-file-name)))
               ;; Display the line and column numbers
               '(:eval (propertize " (%l:%c)" 'face (buffer-file-name)))
               ;; Conditionally display the elapsed clock time
               '(:eval (when (org-clock-is-active)
                         (let* ((clocked-time (org-clock-get-clocked-time))
                                (hours (/ clocked-time 60))
                                (minutes (% clocked-time 60)))
                           (propertize (format " [%02d:%02d]" hours minutes) 'face nil))))))

;; Ensure the mode line is updated every second
(setq display-time-default-load-average nil)
(display-time-mode 1)
(setq display-time-interval 1)

;; faster updates
(setq echo-keystrokes 0.001)

;; auto update
(global-auto-revert-mode 1)

;; dont load outdated
(setq load-prefer-newer t)

;; Also auto refresh dired, but be quiet about it
(setq global-auto-revert-non-file-buffers t)
(setq auto-revert-verbose nil)

;; Find-file should automatically create parents
(defun odd/find-file (orig-fun &rest args)
  (let* ((filename (car args))
         (directory (file-name-directory filename)))
    (if (not (file-directory-p directory))
        (make-directory directory t))
    (apply orig-fun args)))

(advice-add 'find-file :around 'odd/find-file)

;; Silence useless messages
(defun advice-silence-messages (orig-fun &rest args)
  "Advice function that silences all messages in ORIG-FUN."
  (let ((inhibit-message t)      ;Don't show the messages in Echo area
        (message-log-max nil))   ;Don't show the messages in the *Messages* buffer
    (apply orig-fun args)))

(dolist (fn '(push-mark pop-mark))
  (advice-add fn :around #'advice-silence-messages))

(defadvice previous-line (around silencer activate)
  (condition-case nil
      ad-do-it
    ((beginning-of-buffer))))

(defadvice next-line (around silencer activate)
  (condition-case nil
      ad-do-it
    ((beginning-of-buffer))))

(defadvice dired-jump (around silencer activate)
  (condition-case nil
      ad-do-it
    ((beginning-of-buffer))))

(setq-default cursor-in-non-selected-windows nil) ;; don't show cursor in inactive window

;; smooth scrolling
(pixel-scroll-precision-mode t)
