;;; -*- lexical-binding: t; -*-

(use-package org-roam
  :straight t
  :custom
  (org-roam-directory "/home/odd/source/notes")
  :bind (("C-c o l" . org-roam-buffer-toggle)
         ("C-c o f" . org-roam-node-find)
         ("C-c o i" . org-roam-node-insert))
  :config
  (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
  (org-roam-db-autosync-enable))

(use-package markdown-mode
  :straight t)

(use-package zig-mode
  :straight t)

(use-package nix-mode
  :straight t)

(use-package sudo-edit
  :straight t)

(use-package just-mode
  :straight t)

(use-package yaml-mode
  :straight t)

(use-package rainbow-mode
  :straight t)

(use-package coverlay
  :straight t)

(use-package origami
  :straight t)

(use-package restclient
  :straight t)

(use-package dart-mode
  :straight t)

(use-package org-modern
  :straight t
  :init
  (with-eval-after-load 'org (global-org-modern-mode)))

(use-package treesit-auto
  :straight t
  :config
  (global-treesit-auto-mode))

(defun restclient-new-buffer ()
  (interactive)
  (xah-new-empty-buffer)
  (restclient-mode))

(use-package rust-ts-mode
  :mode (("\\.rs\\'" . rust-ts-mode)))

(use-package xah-fly-keys
  :straight t
  :init
  (require 'xah-fly-keys)
  (xah-fly-keys-set-layout "colemak")
  (global-set-key (kbd "<escape>") 'xah-fly-command-mode-activate)
  (xah-fly-keys)

  ;; keybindings
  (define-key xah-fly-command-map (kbd "A") 'org-agenda)
  (define-key xah-fly-command-map (kbd "E") 'odd/open-vterm)
  (define-key xah-fly-command-map (kbd "C-S-e") 'odd/open-vterm-in-project-root)
  (define-key xah-fly-command-map (kbd "V") 'vterm)
  (define-key xah-fly-command-map (kbd "U") 'winner-undo)
  (define-key xah-fly-command-map (kbd "G") 'magit)
  (define-key xah-fly-command-map (kbd "R") 'consult-ripgrep)
  (define-key xah-fly-command-map (kbd "H") '(lambda () (interactive) (gptel "*ChatGPT*") (switch-to-buffer "*ChatGPT*")))
  (define-key xah-fly-command-map (kbd "F") 'consult-find)
  (define-key xah-fly-command-map (kbd "C") 'org-capture)
  (define-key xah-fly-command-map (kbd "N") 'notmuch)
  (define-key xah-fly-command-map (kbd "P") 'project-find-file)
  (define-key xah-fly-command-map (kbd "k") 'consult-line)
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

(use-package vim-tab-bar
  :straight (:type git :host github :repo "jamescherti/vim-tab-bar.el")
  :custom
  (tab-bar-show 1)
  :init
  (tab-bar-mode t)
  (tab-bar-history-mode t)
  (global-set-key (kbd "C-w") 'tab-bar-close-tab)
  (global-set-key (kbd "C-t") 'tab-bar-new-tab)
  (global-set-key (kbd "C-<tab>") 'tab-bar-switch-to-next-tab)
  (global-set-key (kbd "C-S-<iso-lefttab>") 'tab-bar-switch-to-prev-tab)
  (dolist (n (number-sequence 1 9))
    (global-set-key (kbd (format "M-%d" n))
                    (let ((tab-number n))
                      (lambda () (interactive) (tab-bar-select-tab tab-number)))))
  :config
  (add-hook 'after-init-hook #'vim-tab-bar-mode))

(use-package catppuccin-theme
  :straight t
  :config
  (load-theme 'catppuccin t))

(use-package dired-open
  :straight t)

(use-package dired
  :defer t
  :hook ((dired-mode . dired-hide-details-mode)
         (dired-mode . dired-omit-mode))
  :init
  (define-key dired-mode-map (kbd "i") 'wdired-change-to-wdired-mode)
  (define-key dired-mode-map (kbd "J") 'dired-open-xdg)
  (define-key dired-mode-map (kbd ".") 'dired-omit-mode)
  (define-key dired-mode-map [mouse-2] 'dired-mouse-find-file)
  (define-key global-map [mouse-3] 'dired-jump)
  :custom
  (dired-omit-files "\\(^\\..*\\|node_modules\\|_build\\|deps\\|Dockerfile\\|fly.toml\\|bun\\.lockb\\)")
  (dired-dwim-target t)
  (dired-omit-verbose nil)
  (dired-free-space nil)
  (dired-listing-switches "--group-directories-first --dereference -Alvh"))

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

(defun org-toggle-partial-checkbox ()
  "Toggle the current Org mode checkbox to/from the partially completed state."
  (interactive)
  ;; Explicitly save the cursor position
  (let ((pos (point)))
    (beginning-of-line)
    (if (looking-at "\\(.*\\)- \\[ \\]\\(.*\\)")
        (replace-match "\\1- [-]\\2")
      (if (looking-at "\\(.*\\)- \\[\\-\\]\\(.*\\)")
          (replace-match "\\1- [ ]\\2")))
    ;; Restore the cursor to its original position
    (goto-char pos)))

(use-package org
  :hook (org-mode . org-indent-mode)
  :custom
  (org-confirm-babel-evaluate nil)
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
     ("\\.x?html?\\'" . "firefox %s")
     ("\\.pdf\\'" . "firefox %s"))))
  :init
  (define-key org-mode-map (kbd "C-c -") 'org-toggle-partial-checkbox))

(use-package org-agenda
  :custom
  (org-agenda-start-on-weekday nil)
  (org-agenda-files '("~/source/org/work.org")))

(use-package eldoc
  :init
  (global-eldoc-mode)
  :custom
  (eldoc-idle-delay 0)
  (eldoc-echo-area-use-multiline-p nil)
  (eldoc-echo-area-display-truncation-message nil))

(use-package paren-face
  :straight t
  :init
  (global-paren-face-mode))

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
  :init
  (define-key vterm-mode-map (kbd "<escape>") 'xah-fly-command-mode-activate)
  (defun odd/open-vterm ()
    (interactive)
    ;; if current buffer is vterm, delete its window, otherwise
    ;; find vterm buffer that matches current directory, otherwise
    ;; open new vterm buffer
    (if (string= "vterm-mode" (symbol-name major-mode))
        (delete-window)
      (let* ((buffer-directory (expand-file-name (directory-file-name default-directory)))
             (current-buffer-name (format "vterm odd:%s" buffer-directory))
             (matching-buffer (get-buffer current-buffer-name)))
        (split-window-below)
        (other-window 1)
        (if matching-buffer
            (switch-to-buffer matching-buffer)
          (vterm)))))

  (defun odd/get-project-root ()
    "Get the project root directory if available."
    (or (project-root (project-current))
        (locate-dominating-file default-directory ".git")
        default-directory))
  
  (defun odd/open-vterm-in-project-root ()
    (interactive)
    ;; if current buffer is vterm, delete its window, otherwise
    ;; find vterm buffer that matches project root directory, otherwise
    ;; open new vterm buffer in project root
    (if (string= "vterm-mode" (symbol-name major-mode))
        (delete-window)
      (let* ((project-root (odd/get-project-root))
             (buffer-directory (expand-file-name (directory-file-name project-root)))
             (current-buffer-name (format "vterm odd:%s" buffer-directory))
             (matching-buffer (get-buffer current-buffer-name)))
        (split-window-below)
        (other-window 1)
        (if matching-buffer
            (switch-to-buffer matching-buffer)
          (let ((default-directory buffer-directory))
            (vterm)
            (rename-buffer current-buffer-name)))))))

(use-package hyperbole
  :straight t
  :config
  (hyperbole-mode))

(use-package zoom
  :straight t
  :custom
  (zoom-size '(0.618 . 0.618))
  :init
  (zoom-mode t))

(use-package asm-mode
  :hook (asm-mode . (lambda (electric-indent-mode -1))))

(use-package typst-mode
  :mode (("\\.typst\\'" . typst-mode))
  :straight (:type git :host github :repo "Ziqi-Yang/typst-mode.el"))

(use-package lsp-bridge
  :straight '(lsp-bridge :type git :host github :repo "manateelazycat/lsp-bridge"
                         :files (:defaults "*.el" "*.py" "acm" "core" "langserver" "multiserver" "resources")
                         :build (:not compile))
  :custom
  (acm-enable-yas nil)
  (acm-enable-icon nil)
  (acm-enable-tabnine nil)
  (acm-enable-codeium nil)
  (acm-enable-capf t)
  (acm-enable-search-file-words nil)
  (acm-doc-frame-max-lines 25)
  (lsp-bridge-nix-lsp-server "nil")
  (lsp-bridge-enable-hover-diagnostic t)
  (lsp-bridge-code-action-enable-popup-menu nil)
  (lsp-bridge-enable-inlay-hint nil)
  (lsp-bridge-inlay-hint-overlays '())
  :init
  (setq-default lsp-bridge-enable-inlay-hint nil)
  (global-lsp-bridge-mode)
  (let ((filtered-list (cl-delete 'lsp-bridge-not-match-hide-characters lsp-bridge-completion-popup-predicates)))
    (setq lsp-bridge-completion-popup-predicates filtered-list))
  ;; <ret> is very annoying because lsp-bridge is too fast, unset it
  (keymap-unset acm-mode-map "RET")
  (define-key lsp-bridge-mode-map (kbd "C-c e") 'lsp-bridge-diagnostic-jump-next)
  (define-key lsp-bridge-mode-map (kbd "C-c f") 'lsp-bridge-find-def)
  (define-key lsp-bridge-mode-map (kbd "C-c n") 'lsp-bridge-rename)
  (define-key lsp-bridge-mode-map (kbd "C-c a") 'lsp-bridge-code-action)
  (define-key lsp-bridge-mode-map (kbd "C-c r") 'lsp-bridge-find-references)
  (define-key lsp-bridge-mode-map (kbd "C-c h") 'lsp-bridge-popup-documentation))

(use-package envrc
  :straight t
  :init
  (envrc-global-mode))

(use-package sly
  :straight t
  :init
  (setq inferior-lisp-program "sbcl")
  (define-key xah-fly-command-map (kbd "SPC , r") 'sly-eval-last-expression)
  (define-key xah-fly-command-map (kbd "SPC , s") 'sly-eval-defun)
  (define-key xah-fly-command-map (kbd "SPC , t") 'sly-eval-region)
  (define-key xah-fly-command-map (kbd "SPC , d") 'sly-eval-buffer))

(use-package puni
  :straight t
  :hook (lisp-mode . puni-mode))

(use-package lisp-mode
  :hook (lisp-mode . electric-pair-mode))

(use-package emmet-mode
  :straight t
  :custom
  (emmet-indentation 2)
  (emmet-indent-after-insert nil)
  (emmet-insert-flash-time 0.25)
  :config
  (keymap-unset emmet-mode-keymap "C-j")
  (define-key emmet-mode-keymap (kbd "C-w") 'emmet-wrap-with-markup)
  (define-key emmet-mode-keymap (kbd "C-e") 'emmet-expand-line))

(add-hook 'html-mode-hook 'emmet-mode)
(add-hook 'html-mode-hook 'sgml-electric-tag-pair-mode)
(add-to-list 'auto-mode-alist '("\\.html\\'" . html-mode))

(use-package svelte-mode
  :hook ((svelte-mode . emmet-mode)
         (svelte-mode . sgml-electric-tag-pair-mode)
         (svelte-mode . (lambda () (rainbow-delimiters-mode -1))))
  :straight t)

(use-package css-mode
  :mode (("\\.postcss\\'" . css-mode))
  :custom
  (css-indent-offset 2))

(use-package gradle-mode
  :straight t)

(use-package php-mode
  :straight t)

(use-package olivetti
  :straight t
  :custom
  (olivetti-mode-on-hook nil)
  :hook ((prog-mode . olivetti-mode)
         (dired-mode . olivetti-mode)
         (org-mode . olivetti-mode)
         (image-mode . olivetti-mode)))

(use-package elixir-ts-mode
  :init
  (setq lsp-bridge-elixir-lsp-server "nextls")
  :mode (("\\.ex\\'" . elixir-ts-mode)
         ("\\.exs\\'" . elixir-ts-mode))
  :hook ((elixir-ts-mode . emmet-mode)
         (heex-ts-mode . emmet-mode)))

(use-package gradle-mode
  :straight t)

(use-package typescript-mode
  :straight t)

(use-package tsx-ts-mode
  :mode ("\\.tsx\\'" . tsx-ts-mode)
  :hook ((tsx-ts-mode . emmet-mode )
         (tsx-ts-mode . sgml-electric-tag-pair-mode)))

(use-package typescript-ts-mode
  :mode ("\\.ts\\'" . typescript-ts-mode)
  :hook ((tsx-ts-mode . emmet-mode )
         (tsx-ts-mode . sgml-electric-tag-pair-mode)))
