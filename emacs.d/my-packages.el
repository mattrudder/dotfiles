;;; my-packages.el --- My package list
;;; Commentary:

;;; Code:
;(require 'cl)
(require 'package)

(add-to-list 'package-archives
	     '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives
	     '("marmalade" . "http://marmalade-repo.org/packages/") t)

(package-initialize)

(defvar required-packages
  '(
    magit
    popup
    popwin
    direx
    ; Snippets
    yasnippet
    ; Text Completion
    company
    ; Syntax Checking
    flycheck
    ; Multiple Cursors
    multiple-cursors
    mc-extras
    ; C++
    irony
    company-irony
    flycheck-irony
    ; Rust
    cargo
    racer
    company-racer
    flycheck-rust
    rust-mode
    rustfmt
    ; .NET
    csharp-mode
    fsharp-mode
    omnisharp
    ; Elixir
    elixir-mode
    alchemist
    flycheck-dialyzer
    ; Graphics Programming
    glsl-mode
    ; Utilities
    drag-stuff
    )
  )

(defun packages-installed-p ()
  (loop for p in required-packages
	when (not (package-installed-p p)) do (return nil)
	finally (return t)))

(unless (packages-installed-p)
  ; check for new packages (package versions)
  (message "%s" "Emacs is now refreshing its package database...")
  (package-refresh-contents)
  (message "%s" " done.")

  ; install the missing packages
  (dolist (p required-packages)
    (when (not (package-installed-p p))
      (package-install p))))

(provide 'my-packages)
;;; my-packages.el ends here
