;;; config.el -*- lexical-binding: t -*-

(use-package treesit-auto
  :straight t
  :config
  (global-treesit-auto-mode))

(use-package xah-fly-keys
  :straight t
  :init
  (require 'xah-fly-keys)
  (xah-fly-keys-set-layout "colemak")
  (global-set-key (kbd "<escape>") 'xah-fly-command-mode-activate)
  (xah-fly-keys)
  (add-hook 'xah-fly-command-mode-activate-hook (lambda () (interactive) (corfu-quit)))

  ;; keybindings
  (define-key xah-fly-command-map (kbd "A") 'org-agenda)
  (define-key xah-fly-command-map (kbd "E") 'odd/open-vterm)
  (define-key xah-fly-command-map (kbd "V") 'vterm)
  (define-key xah-fly-command-map (kbd "U") 'winner-undo)
  (define-key xah-fly-command-map (kbd "G") 'magit)
  (define-key xah-fly-command-map (kbd "T") 'gptel)
  (define-key xah-fly-command-map (kbd "R") 'consult-ripgrep)
  (define-key xah-fly-command-map (kbd "F") 'consult-find)
  (define-key xah-fly-command-map (kbd "C") 'org-capture)
  (define-key xah-fly-command-map (kbd "N") 'notmuch)
  (define-key xah-fly-command-map (kbd "k") 'consult-line)
  (define-key xah-fly-command-map (kbd "P") 'project-find-file)
  (define-key xah-fly-command-map (kbd ":") 'eval-expression)
  (define-key xah-fly-command-map (kbd "5") 'split-window-right)
  (define-key xah-fly-command-map (kbd "C-o") 'pop-to-mark-command)
  
  ;; kill buffer
  (define-key global-map (kbd "C-x k") 'kill-this-buffer)  

  ;; cycle org-agenda-files
  (define-key global-map (kbd "C-'") 'org-cycle-agenda-files)

  ;; moving windows
  (define-key global-map (kbd "M-<up>") 'windmove-swap-states-up)
  (define-key global-map (kbd "M-<down>") 'windmove-swap-states-down)
  (define-key global-map (kbd "M-<left>") 'windmove-swap-states-left)
  (define-key global-map (kbd "M-<right>") 'windmove-swap-states-right)

  ;; remove bad bindings
  (global-unset-key (kbd "C-w"))
  
  ;; keybindings leader
  (define-key xah-fly-leader-key-map (kbd "t") 'consult-buffer))

(use-package markdown-mode
  :straight t)

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

(use-package catppuccin-theme
  :straight t)
  ;; :config
  ;; (if recording-video
  ;;     (load-theme 'catppuccin t)))

(use-package doom-themes
  :straight t)
  ;; :config
  ;; (if (not recording-video) 
      ;; (progn
        ;; fix color for lsp-ui-doc
        ;; (load-theme 'doom-flatwhite t)
        ;; (require 'markdown-mode)
        ;; (set-face-background 'markdown-code-face "#f1ece4"))))

(use-package theme-changer
  :demand t
  :straight t
  :custom
  (calendar-location-name "Froland, Norway") 
  (calendar-latitude 58.0)
  (calendar-longitude 9.0)
  :config
  (change-theme 'doom-flatwhite 'catppuccin))

(use-package dired
  :defer t
  :hook ((dired-mode . dired-hide-details-mode)
         (dired-mode . dired-omit-mode))
  :init
  (define-key dired-mode-map (kbd "i") 'wdired-change-to-wdired-mode)
  (define-key dired-mode-map (kbd ".") 'dired-omit-mode)
  (define-key dired-mode-map [mouse-2] 'dired-mouse-find-file)
  (define-key global-map [mouse-3] 'dired-jump)
  :custom
  (dired-omit-files "^\\.")
  (dired-dwim-target t)
  (dired-omit-verbose nil)
  (dired-free-space nil)
  (dired-listing-switches "--group-directories-first --dereference -Alvh"))

(use-package flycheck
  :straight t)

(use-package lsp-ui
  :straight t
  :custom
  (lsp-ui-doc-max-width 45)
  (lsp-ui-doc-max-height 20)
  (lsp-ui-doc-show-with-cursor t)
  (lsp-ui-doc-show-with-mouse nil)
  (lsp-ui-doc-delay 0.25))

(use-package lsp-mode
  :straight t
  :init
  (define-key lsp-mode-map (kbd "C-c e") 'flycheck-next-error)
  (define-key lsp-mode-map (kbd "C-c f") 'lsp-find-definition)
  (define-key lsp-mode-map (kbd "C-c n") 'lsp-rename)
  (define-key lsp-mode-map (kbd "C-c a") 'lsp-execute-code-action)
  (define-key lsp-mode-map (kbd "C-c r") 'lsp-find-references)
  (add-hook 'rust-ts-mode-hook 'lsp-deferred)
  (add-hook 'zig-mode-hook 'lsp-deferred)
  :custom
  (lsp-enable-suggest-server-download nil)
  (lsp-auto-guess-root t)
  (lsp-idle-delay 0.500)
  (lsp-log-io nil)
  (lsp-headerline-breadcrumb-enable nil)
  (lsp-lens-enable nil)
  (lsp-signature-auto-activate nil)
  (lsp-completion-provider :none)
  (lsp-rust-analyzer-diagnostics-disabled ["unresolved-proc-macro"]))

(use-package zig-mode
  :straight t)

(use-package rust-ts-mode
  :mode (("\\.rs\\'" . rust-ts-mode)))

(use-package nix-mode
  :straight t)

(use-package csharp-mode
  :straight t
  :mode (("\\.cs\\'" . csharp-mode)
         ("\\.cshtml\\'" . mhtml-mode)))

(use-package sudo-edit
  :straight t)

(use-package consult
  :straight t
  :custom
  (consult-preview-key nil)
  (consult-buffer-sources '(consult--source-buffer)))

(use-package vertico
  :straight t
  :custom
  (vertico-count-format '("" . ""))
  :init
  (vertico-mode t))

(use-package orderless
  :straight t
  :custom
  (completion-styles '(orderless))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion))))
  (selectrum-highlight-candidates-function #'orderless-highlight-matches))

(use-package marginalia
  :straight t
  :init
  (marginalia-mode t))

(use-package which-key
  :straight t
  :custom
  (which-key-idle-delay 0.5)
  :config
  (which-key-mode t))

(use-package corfu
  :straight t
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-count 5)
  (corfu-auto-prefix 1)
  (corfu-auto-delay 0.5)
  (corfu-quit-no-match t)
  :config
  (global-corfu-mode))

(use-package cape
  :straight t
  :init
  (add-to-list 'completion-at-point-functions #'cape-file))

(use-package magit
  :straight t
  :custom (magit-refresh-status-buffer nil))

(use-package yasnippet
  :straight t
  :init
  (yas-global-mode t)
  (define-key yas-minor-mode-map (kbd "<tab>") nil)
  (define-key yas-minor-mode-map (kbd "TAB") nil)
  (define-key yas-minor-mode-map (kbd "SPC") yas-maybe-expand))

(use-package org
  :hook (org-mode . org-indent-mode)
  :custom
  (org-hidden-keywords nil)
  (org-hide-emphasis-markers t)
  (org-image-actual-width (list 250))
  (org-return-follows-link t)
  (org-edit-src-content-indentation 0)
  (org-html-validation-link t)
  (org-html-head-include-scripts nil)
  (org-html-head-include-default-style nil)
  (org-html-html5-fancy t)
  (org-html-doctype "html5")
  (org-html-htmlize-output-type 'inline)
  (org-file-apps
   (quote
    ((auto-mode . emacs)
     ("\\.mm\\'" . default)
     ("\\.x?html?\\'" . "brave %s")
     ("\\.pdf\\'" . "brave %s"))))
  :config
  (set-face-attribute 'org-document-info-keyword nil
                      :foreground "#9d8f7c")
  (set-face-attribute 'org-document-info nil
                      :foreground "#9d8f7c")
  (set-face-attribute 'org-document-title nil
                      :foreground "#9d8f7c" :bold nil))

(use-package org-agenda
  :custom
  (org-agenda-start-on-weekday nil)
  (org-agenda-files '("~/source/org/work")))

(use-package eldoc
  :custom
  (eldoc-echo-area-use-multiline-p nil)
  (eldoc-echo-area-display-truncation-message nil))

(use-package rainbow-delimiters
  :straight t
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package vterm
  :straight t
  :custom
  (vterm-always-compile-module t)
  (vterm-buffer-name-string "vterm %s")
  (vterm-timer-delay 0.01)
  :config
  (defun vterm-directory-sync (&rest _)
    "Synchronize current working directory."
    (interactive)
    (when (and vterm--process (equal major-mode 'vterm-mode))
      (let* ((pid (process-id vterm--process))
             (dir (file-truename (format "/proc/%d/cwd/" pid))))
        (setq default-directory dir))))
  (advice-add #'dired-jump :before #'vterm-directory-sync)
  (define-key vterm-mode-map (kbd "C-v") 'vterm-yank)
  (define-key vterm-mode-map (kbd "C-u") 'vterm-send-C-u)
  (define-key vterm-mode-map (kbd "M-<up>") 'windmove-swap-states-up)
  (define-key vterm-mode-map (kbd "M-<down>") 'windmove-swap-states-down)
  (define-key vterm-mode-map (kbd "M-<left>") 'windmove-swap-states-left)
  (define-key vterm-mode-map (kbd "M-<right>") 'windmove-swap-states-right))

(use-package vterm-toggle
  :straight t
  :config
  (define-key vterm-mode-map (kbd "<escape>") 'xah-fly-command-mode-activate)
  :hook
  (vterm-toggle-show . xah-fly-insert-mode-activate))

(defun odd/open-vterm ()
  (interactive)
  ;; if current buffer is vterm, delete its window, otherwise
  ;; find vterm buffer that matches current directory, otherwise
  ;; open new vterm buffer
  (require 'vterm-toggle)
  (if (string-match-p "vterm" (buffer-name))
      (delete-window)
    (let* ((buffer-directory (expand-file-name (directory-file-name default-directory)))
           (buffer-name (format "vterm %s" buffer-directory))
           (matching-buffer (get-buffer buffer-name)))
      (progn
        (split-window-below)
        (other-window 1)
        (if matching-buffer
            (switch-to-buffer matching-buffer)
          (vterm))))))
 
(use-package envrc
  :straight t
  :init
  (envrc-global-mode))

(use-package emms
  :straight t
  :custom
  (emms-source-file-default-directory "~/source/quran")
  :config
  (emms-all)
  (emms-default-players))

(use-package hyperbole
  :straight t
  :config
  (hyperbole-mode))

(use-package prettify-symbols-mode
  :hook (elisp-mode . prettify-symbols-mode)
  :config
  (defconst lisp--prettify-symbols-alist
    '(("lambda"  . ?λ))))

(use-package paredit
  :hook ((lisp-mode . paredit-mode)
         (emacs-lisp-mode . paredit-mode)) 
  :straight t)

(use-package just-mode
  :straight t)

(use-package yaml-mode
  :straight t)

(use-package rainbow-mode
  :straight t)

(defun odd/run-octave ()
  (interactive)
  (save-buffer)
  (message nil)
  (let* ((path (buffer-file-name (window-buffer (minibuffer-selected-window))))
         (output (shell-command-to-string (format "octave --no-gui --persist %s" path)))
         (buffer (get-buffer-create "*octave*")))
    (with-current-buffer buffer
      (visual-line-mode)
      (erase-buffer)
      (insert (s-trim output)))
    (if (> (buffer-size buffer) 0)
        (progn
          (display-buffer-in-side-window buffer '(( side . right)))
          (balance-windows)))))

(use-package octave
  :mode (("\\.m\\'" . octave-mode))
  :bind (("C-c C-c" . odd/run-octave)))

(use-package ac-octave
  :hook ((octave-mode . ac-octave-setup)
         (octave-mode . auto-complete-mode))
  :straight t)

(use-package coverlay
  :straight t)

(use-package origami
  :straight t)

(use-package css-in-js-mode
  :straight '(css-in-js-mode :type git :host github :repo "orzechowskid/tree-sitter-css-in-js"))

(use-package tsx-mode
  :straight '(tsx-mode :type git :host github :repo "orzechowskid/tsx-mode.el" :branch "emacs29")
  :init
  (add-hook 'tsx-ts-mode-hook 'lsp)
  (add-hook 'typescript-ts-mode-hook 'lsp))

(use-package wgsl-mode
  :straight '(wgsl-mode :type git :host github :repo "acowley/wgsl-mode"))

(use-package zoom
  :straight t
  :custom
  (zoom-size '(0.618 . 0.618))
  :init
  (zoom-mode t))

(use-package emmet-mode
  :straight t
  :hook (typescript-ts-mode . emmet-mode)
  :custom
  (emmet-indentation 2)
  (emmet-indent-after-insert nil)
  (emmet-insert-flash-time 0.25))

(use-package svelte-mode
  :hook ((svelte-mode . emmet-mode)
         (svelte-mode . lsp-deferred)
         (svelte-mode . (lambda () (rainbow-delimiters-mode -1))))
  :straight t)

(use-package javascript-mode
  :mode (("\\.js\\'" . javascript-mode)
         ("\\.cjs\\'" . javascript-mode))
  :hook (javascript-mode . lsp-deferred)
  :custom
  (js-indent-level 2))

(use-package typescript-mode
  :hook (typescript-mode . lsp-deferred)
  :custom
  (typescript-indent-level 2)
  :straight t)

(use-package css-mode
  :mode (("\\.postcss\\'" . css-mode))
  :custom
  (css-indent-offset 2))

(use-package lsp-dart
  :straight t)

(use-package dart-mode
  :straight t
  :hook (dart-mode . lsp-deferred))

(use-package mhtml-mode
  :hook (mhtml-mode . emmet-mode))

(use-package asm-mode
  :hook (asm-mode . (lambda (electric-indent-mode -1))))

(use-package vlang-mode
  :straight '(vlang-mode :type git :host github :repo "Naheel-Azawy/vlang-mode"))

(use-package writeroom-mode
  :straight t)

(use-package typst-mode
  :mode (("\\.typst\\'" . typst-mode))
  :hook ((typst-mode . (lambda () (eletric-pair-mode -1))))
  :straight (:type git :host github :repo "Ziqi-Yang/typst-mode.el"))

(defun browse-web ()
  (interactive)
  (let ((input (read-string "Search for: ")))
    (shell-command (concat "brave " "https://www.google.com/search?q=" "'" input "'"))))

(provide 'init)
