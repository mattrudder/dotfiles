(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;(use-package ido-completing-read+
;  :ensure t
;  :config
;  (ido-mode t)
;  (ido-everywhere t)
;  (setq ido-enable-flex-matching t)
;  (setq ido-use-filename-at-point nil)
;  (setq ido-use-virtual-buffers t))


;(use-package smex
;  :ensure t
;  :config
;  (smex-initialize)
;  (global-set-key (kbd "M-x") 'smex)
;  (global-set-key (kbd "C-c C-c M-x") 'execute-extended-command))

(use-package counsel
  :ensure t
  :config
  (setopt ivy-use-virtual-buffers t)
  (setopt ivy-count-format "(%d/%d)")
  (ivy-mode 1))

(use-package multiple-cursors
  :ensure t
  :config
  (global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
  (global-set-key (kbd "C->") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)
  (global-set-key (kbd "C-\"") 'mc/skip-to-next-like-this)
  (global-set-key (kbd "C-:") 'mc/skip-to-previous-like-this))


(use-package cmake-mode
  :ensure t)

(use-package flycheck
  :ensure t
  :config
  (add-hook 'after-init-hook #'global-flycheck-mode)
  (setq-default flycheck-disabled-checkers '(emacs-lisp-checkdoc)))


(use-package lsp-mode
  :ensure t
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook (
		 (c-mode . lsp-deferred)
		 (c++-mode . lsp-deferred)
		 (lsp-mode . lsp-enable-which-key-integration))
  :bind (:map lsp-mode-map
			  ("M-RET" . lsp-execute-code-action))
  :commands (lsp lsp-deferred))

(use-package lsp-ui
  :ensure t
  :bind (:map lsp-mode-map
			  ([remap xref-find-definitions] . lsp-ui-peek-find-definitions)
			  ([remap xref-find-references] . lsp-ui-peek-find-references))
  :config
  (lsp-ui-peek-enable 1)
  (lsp-ui-doc-enable 1)
  :commands lsp-ui-mode)

(use-package which-key
  :ensure t
  :config
  (which-key-mode))
