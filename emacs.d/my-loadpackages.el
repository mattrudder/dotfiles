;;; my-loadpackages.el --- Configuration for packages loaded from MELPA

;;; Code:
(load "~/.emacs.d/my-packages.el")

(require 'magit)
(define-key global-map (kbd "C-c m") 'magit-status)

(require 'yasnippet)
(yas-global-mode 1)
(yas-load-directory "~/.emacs.d/snippets")
(add-hook 'term-mode-hook (lambda() (setq yas-dont-activate t)))

; Popwin
(require 'popwin)
(popwin-mode)

; Direx
(require 'direx)
(setq direx:leaf-icon "  "
      direx:open-icon "▾ "
      direx:closed-icon "▸ ")
(push '(direx:direx-mode :position left :width 35 :dedicated t)
      popwin:special-display-config)
(global-set-key (kbd "C-\\") 'direx-project:jump-to-project-root-other-window)

(global-flycheck-mode)

; Company
(require 'company)
(global-company-mode)
(setq company-idle-delay 0.2)
(setq company-minimum-prefix-length 1)
(setq company-tooltip-align-annotations t)

; Rust
(require 'rust-mode)
(require 'racer)
(setq racer-cmd (expand-file-name "~/src/thirdparty/racer/target/release/racer"))
(setq racer-rust-src-path (expand-file-name "~/src/thirdparty/rust/src"))
(unless (getenv "RUST_SRC_PATH")
  (setenv "RUST_SRC_PATH" (expand-file-name "~/src/thirdparty/rust/src")))

(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))
(add-hook 'rust-mode-hook #'company-mode)
(add-hook 'rust-mode-hook #'racer-mode)
(add-hook 'rust-mode-hook #'rustfmt-enable-on-save)
(add-hook 'racer-mode-hook #'eldoc-mode)
(add-hook 'rust-mode-hook
	  '(lambda()
	     (add-hook 'flycheck-mode-hook #'flycheck-rust-setup)
 	     (local-set-key (kbd "M-.") #'racer-find-definition)
	     (local-set-key (kbd "TAB") #'company-indent-or-complete-common)))

; Omnisharp completion
(require 'omnisharp)
(add-hook 'csharp-mode-hook 'omnisharp-mode)
(add-hook 'fsharp-mode-hook 'omnisharp-mode)

(setq omnisharp-server-executable-path (expand-file-name "~/src/thirdparty/omnisharp-server/OmniSharp/bin/Release/OmniSharp.exe"))

; GLSL Mode
(add-to-list 'auto-mode-alist '("\\.vsh\\'" . glsl-mode))
(add-to-list 'auto-mode-alist '("\\.fsh\\'" . glsl-mode))


(custom-set-variables
 '(rust-rustfmt-bin (expand-file-name "~/.multirust/toolchains/stable/cargo/bin/rustfmt"))
 )

