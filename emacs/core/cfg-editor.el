;; cfg-editor.el
;; by Matt Rudder (matt@mattrudder.com)

(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)

(delete-selection-mode t)

;; diminish keeps the modeline tidy
(require 'diminish)

;; meaningful names for buffers with the same name
(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)
(setq uniquify-separator "/")
(setq uniquify-after-kill-buffer-p t)    ; rename after killing uniquified
(setq uniquify-ignore-buffers-re "^\\*") ; don't muck with special buffers

;; saveplace remembers your location in a file when saving files
(require 'saveplace)
(setq save-place-file (expand-file-name "saveplace" config-savefile-dir))
;; activate it for all buffers
(setq-default save-place t)

;; savehist keeps track of some history
(require 'savehist)
(setq savehist-additional-variables
      ;; search entries
      '(search ring regexp-search-ring)
      ;; save every minute
      savehist-autosave-interval 60
      ;; keep the home clean
      savehist-file (expand-file-name "savehist" config-savefile-dir))
(savehist-mode +1)

;; save recent files
(require 'recentf)
(setq recentf-save-file (expand-file-name "recentf" config-savefile-dir)
      recentf-max-saved-items 500
      recentf-max-menu-items 15)
(recentf-mode +1)

;; bookmarks
(require 'bookmark)
(setq bookmark-default-file (expand-file-name "bookmarks" config-savefile-dir)
      bookmark-save-flag 1)

;; projectile is a project management mode
(require 'projectile)
(setq projectile-cache-file (expand-file-name  "projectile.cache" config-savefile-dir))
(projectile-global-mode t)

;; clean up obsolete buffers automatically
(require 'midnight)

;; whitespace-mode config
(require 'whitespace)
(setq whitespace-line-column 80) ;; limit line length
(setq whitespace-style '(face tabs empty trailing lines-tail))

;; saner regex syntax
(require 're-builder)
(setq reb-re-syntax 'string)

(require 'eshell)
(setq eshell-directory-name (expand-file-name "eshell" config-savefile-dir))

(setq semanticdb-default-save-directory
      (expand-file-name "semanticdb" config-savefile-dir))

;; Compilation from Emacs
(defun config-colorize-compilation-buffer ()
  "Colorize a compilation mode buffer."
  (interactive)
  ;; we don't want to mess with child modes such as grep-mode, ack, ag, etc
  (when (eq major-mode 'compilation-mode)
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region (point-min) (point-max)))))

(require 'compile)
(setq compilation-ask-about-save nil  ; Just save before compiling
      compilation-always-kill t       ; Just kill old compile processes before
                                      ; starting the new one
      compilation-scroll-output 'first-error ; Automatically scroll to first
                                             ; error
      )

;; Colorize output of Compilation Mode, see
;; http://stackoverflow.com/a/3072831/355252
(require 'ansi-color)
(add-hook 'compilation-filter-hook #'config-colorize-compilation-buffer)

;; Set path for libclang, and load irony-mode path
(setenv "LD_LIBRARY_PATH" "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/")
(add-to-list 'load-path 
             (expand-file-name "vendor/irony-mode/elisp" config-dir))

(require 'auto-complete)
(require 'yasnippet)
(require 'irony)

(irony-enable 'ac)

(defun my:c++-hooks ()
  "Enable the hooks in the preferred order: 'yas -> auto-complete -> irony'."
  ;; be cautious, if yas is not enabled before (auto-complete-mode 1), overlays
  ;; *may* persist after an expansion.
  (yas/minor-mode-on)
  (auto-complete-mode 1)
  
  ;; avoid enabling irony-mode in modes that inherits c-mode, e.g: php-mode
  (when (member major-mode irony-known-modes)
    (irony-mode 1)))

(add-hook 'c++-mode-hook 'my:c++-hooks)
(add-hook 'c-mode-hook 'my:c++-hooks)

(require 'gyp-mode)

(provide 'cfg-editor)

