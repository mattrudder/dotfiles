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
  (consult-async-split-style 'semicolon)
  :init
  ;; Route xref result lists through consult's fuzzy, previewable picker instead
  ;; of the plain *xref* buffer. Covers M-. (go-to-definition when there are
  ;; multiple hits) and M-? (`xref-find-references' -> all usages). With eglot
  ;; active these results come from the language server.
  (setq xref-show-xrefs-function #'consult-xref
		xref-show-definitions-function #'consult-xref)
  :bind
  ;; In-file symbol navigation via eglot document symbols (functions, consts,
  ;; child components): fuzzy + fzf-ranked + live preview. Best for jumping
  ;; around inside a large component. M-I widens it to all open buffers.
  (("M-i" . consult-imenu)
   ("M-I" . consult-imenu-multi)))

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
		 (go-mode . eglot-ensure)
		 (typescript-ts-mode . eglot-ensure)
		 (tsx-ts-mode . eglot-ensure))
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
  (completion-category-defaults nil))

;; Tree-sitter: install/manage language grammars and route the *-ts-mode major
;; modes into `auto-mode-alist'. Pins known-good grammar revisions, sidestepping
;; the ABI-version mismatches you can hit when tracking each grammar's master.
(use-package treesit-auto
  :ensure t
  :custom
  ;; Offer to compile a missing grammar the first time you visit such a file.
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; Prepend the nearest ancestor `node_modules/.bin' to a buffer-local
;; `exec-path' (and the subprocess PATH) so eglot launches project-local tools
;; (typescript-language-server, eslint, prettier) instead of a global one.
;;
;; This replaces the add-node-modules-path package, which shells out to
;; `npm bin' -- removed in npm 9+ (errors "Unknown command: bin") -- and has no
;; usable equivalent under Yarn 4. A pure `locate-dominating-file' lookup needs
;; no npm/yarn/node on PATH and works from a GUI Emacs that never sourced the
;; shell. Runs at depth -10 so it precedes `eglot-ensure' on the same hook.
(defun mr/add-node-modules-bin ()
  "Add the nearest ancestor `node_modules/.bin' to buffer-local `exec-path'.
Also prepends it to a buffer-local PATH so spawned processes inherit it."
  (when-let* ((file (or buffer-file-name default-directory))
			  (root (locate-dominating-file
					 file
					 (lambda (dir)
					   (file-directory-p (expand-file-name "node_modules/.bin" dir)))))
			  (bin (expand-file-name "node_modules/.bin" root)))
	(setq-local exec-path (cons bin (remove bin exec-path)))
	(setq-local process-environment
				(cons (concat "PATH=" bin path-separator (getenv "PATH"))
					  process-environment))))

(dolist (hook '(typescript-ts-mode-hook
				tsx-ts-mode-hook
				js-ts-mode-hook))
  (add-hook hook #'mr/add-node-modules-bin -10))

;; File finding: M-o stays on `project-find-file' (bound in init.el), which
;; lists the full git file set and filters with orderless. Combined with the
;; `orderless-component-separator' above, a path-shaped fuzzy query matches
;; without naming each folder in full. consult-fd was a poor fit here -- it
;; hands the query to `fd' as a path *regexp* (so `*' is a quantifier, not a
;; wildcard, and it isn't fuzzy); it remains available via `M-x consult-fd' for
;; regexp/gitignore-aware searches when that's what you want.

;; typescript-language-server drives tsserver, which on a repo this large
;; (~26k .ts/.tsx in twilight) can hit its default heap ceiling and turn slow or
;; unreliable for xref (M-.). Raise tsserver's memory. This entry shadows
;; eglot's built-in mapping (add-to-list prepends) while keeping program/args;
;; the binary still resolves per-project via `mr/add-node-modules-bin'.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
			   '((typescript-ts-mode tsx-ts-mode)
				 . ("typescript-language-server" "--stdio"
					:initializationOptions (:maxTsServerMemory 8192)))))

;; Fuzzy matching WITH score-based ranking. orderless only *filters* -- it never
;; scores, so vertico falls back to sorting survivors by history/length, which
;; buries a long intended path (e.g. .../channel-live/native/components/metadata/
;; index.tsx) under shorter loose-flex matches. `fussy' is a completion style
;; that scores and sorts candidates, floating the best match to the top. It
;; scores via `fzf-native', a C module whose package ships prebuilt binaries for
;; macOS/Windows/Linux -- fast enough for twilight's ~33k candidates with no
;; per-platform compile. fussy becomes the primary style across the board (M-o
;; project files, M-x, buffers, ...), superseding the earlier orderless
;; flex/separator tweaks. It applies to every completion category, including
;; `file'/`find-file' (the earlier partial-completion carve-out was dropped, per
;; preference for fzf everywhere). orderless stays installed as a fallback.
(use-package fzf-native
  :ensure t
  :config
  (fzf-native-load-dyn))

(use-package fussy
  :ensure t
  :after fzf-native
  :config
  ;; Uses fzf-native for both filtering and (batch) scoring/sorting.
  (fussy-setup-fzf))
