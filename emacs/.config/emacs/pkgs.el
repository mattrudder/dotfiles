(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

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

(use-package xref
  :custom
  (xref-search-program 'ripgrep)
  :config
  ;; The "-s 10000" xref hardcodes for windows-nt exceeds the ARG_MAX xargs
  ;; enforces under Git for Windows' bash/MSYS2; pick a value safely under it.
  (setf (alist-get 'ripgrep xref-search-program-alist)
        "xargs -0 -s 2000 rg <C> --null -nH --no-heading --no-messages -g '!*/' -e <R>"))

(use-package vertico
  :ensure t
  :init
  (vertico-mode))

(use-package consult
  :ensure t
  :custom
  (consult-narrow-key "<")
  (consult-async-split-style 'semicolon))

(use-package multiple-cursors
  :ensure t
  :config
  (global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
  (global-set-key (kbd "C->") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)
  (global-set-key (kbd "C-\"") 'mc/skip-to-next-like-this)
  (global-set-key (kbd "C-:") 'mc/skip-to-previous-like-this))

(use-package yasnippet
  :ensure t
  :config
  (add-to-list 'yas-snippet-dirs "~/.config/emacs/snippets")
  (yas-global-mode 1))

(use-package cmake-mode
  :ensure t)

(use-package go-mode
  :ensure t)

(use-package eglot
  :hook ((c-mode . eglot-ensure)
		 (c++-mode . eglot-ensure)
		 (go-mode . eglot-ensure))
  :custom
  (eglot-events-buffer-size 0)
  :init
  ;; Restrict gopls' workspace/symbol search to this module, excluding
  ;; stdlib/dependencies, so consult-eglot-symbols isn't mixed with them.
  ;; Verify against your gopls version's own settings docs if this doesn't
  ;; take effect -- not verified against gopls source itself.
  (setq-default eglot-workspace-configuration
                '(:gopls (
						  :symbolScope "workspace"
									   :usePlaceholders t
									   :staticcheck t
									   :completeUnimported t
						  )))
  :config
  (defvar-local mr/eglot-format-on-save t
	"When non-nil, format the buffer via eglot before saving.
Set to nil (e.g. via a project's .dir-locals.el) to opt out.")
  (put 'mr/eglot-format-on-save 'safe-local-variable #'booleanp)
  (defun mr/maybe-eglot-format-buffer ()
	(when mr/eglot-format-on-save
	  (eglot-format-buffer)))
  (add-hook 'eglot-managed-mode-hook
			(lambda ()
			  (add-hook 'before-save-hook #'mr/maybe-eglot-format-buffer nil t)))
  :bind (:map eglot-mode-map
			  ("M-RET" . eglot-code-actions)
			  ("M-R" . eglot-rename)))

(use-package consult-eglot
  :ensure t
  :after (consult eglot)
  :bind (:map eglot-mode-map
			  ("C-M-." . consult-eglot-symbols)))

(add-hook 'emacs-lisp-mode-hook #'flymake-mode)

(use-package which-key
  :ensure t
  :config
  (which-key-mode))


;; Corfu: Light and modern completion UI
(use-package corfu
  :ensure t
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)                 ;; Enable auto-completion
  (corfu-auto-delay 0.0)         ;; Instant popup on dot
  (corfu-auto-prefix 1)          ;; Trigger after 1 char
  (corfu-cycle t)                ;; Allow cycling through candidates
  (corfu-quit-no-match 'separator)) ;; Quit if no match

;; Cape: Completion At Point Extensions (Bridges LSP to Corfu)
(use-package cape
  :ensure t
  :init
  ;; Add LSP/Capf to the completion list
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

;; Recommended: Use the 'orderless' completion style for better filtering
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles . (partial-completion))))))
