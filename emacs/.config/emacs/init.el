;;; -*- lexical-binding: t; -*-

(setq custom-file "~/.config/emacs/custom.el")
(load-file custom-file)

(defvar mr/frame-font-family "0xProto Nerd Font Propo"
  "Font family used by `mr/set-frame-font-size'.")
(defconst mr/frame-font-default-size
  (cond
   ((eq system-type 'darwin) 18)
   (t 12))
  "Point size `mr/reset-frame-font-size' restores.")
(defvar mr/frame-font-size mr/frame-font-default-size
  "Current point size used by `mr/set-frame-font-size'.")

(defun mr/set-frame-font-size (&optional frame)
  "Set `mr/frame-font-family' at `mr/frame-font-size' on FRAME (or the
selected frame). Applies per-frame only; never t/all-frames (that resizes
every frame at once and crashes niri under XWayland)."
  (interactive)
  (let ((font-str (format "%s %d" mr/frame-font-family mr/frame-font-size)))
	(setf (alist-get 'font default-frame-alist) font-str)
	(when (display-graphic-p frame)
	  (set-frame-font font-str nil (list (or frame (selected-frame)))))))

(defun mr/increase-frame-font-size ()
  (interactive)
  (setq mr/frame-font-size (1+ mr/frame-font-size))
  (mr/set-frame-font-size))

(defun mr/decrease-frame-font-size ()
  (interactive)
  (setq mr/frame-font-size (max 1 (1- mr/frame-font-size)))
  (mr/set-frame-font-size))

(defun mr/reset-frame-font-size ()
  (interactive)
  (setq mr/frame-font-size mr/frame-font-default-size)
  (mr/set-frame-font-size))

(mr/set-frame-font-size)
(add-hook 'after-make-frame-functions #'mr/set-frame-font-size)

;; Re-assert the font after the daemon's first client frame is realized;
;; applying it during frame creation lands on a tiny fallback font.
(add-hook 'server-after-make-frame-hook
		  (lambda ()
			(run-at-time 0 nil #'mr/set-frame-font-size (selected-frame))))

(column-number-mode 1)
(electric-pair-mode 1)

(global-display-line-numbers-mode 1)

;; macOS (NS) renders `visible-bell' as a large caution icon centered on the
;; frame instead of a window flash, and there's no mac-specific variable to
;; change that -- only `visible-bell' and `ring-bell-function' exist. Override
;; the bell on darwin with a subtle mode-line flash (the closest thing to a
;; flash on NS); Windows/Linux keep their native `visible-bell' window flash.
(defun mr/flash-mode-line ()
  "Briefly invert the mode line as a visual bell."
  (let ((face (if (facep 'mode-line-active) 'mode-line-active 'mode-line)))
	(invert-face face)
	(run-with-timer 0.1 nil #'invert-face face)))
(when (eq system-type 'darwin)
  (setq ring-bell-function #'mr/flash-mode-line))

(when (eq system-type 'windows-nt)
  (setq shell-file-name "C:/Program Files/Git/usr/bin/bash.exe")
  (setq shell-command-switch "-lc"))

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta)
  (setq mac-right-command-modifier 'meta)
  (setq mac-option-modifier 'none)
  (when (display-graphic-p)
	(x-focus-frame nil)))

(defun my/open-dired-if-empty ()
  "Open Dired in the current directory if no files were opened."
  (when (<= (length (buffer-list)) 1) ; Only *scratch* or no buffers exist
    (dired default-directory)))

;; For standard emacs launch
(add-hook 'emacs-startup-hook #'my/open-dired-if-empty)

;; For emacsclient launch (every time a new client frame is created)
(add-hook 'server-after-make-frame-hook #'my/open-dired-if-empty)


(require 'ansi-color)
(defun mr/colorize-compilation-buffer ()
  (let ((inhibit-read-only t))
	(ansi-color-apply-on-region (point-min) (point-max))))

(add-hook 'compilation-filter-hook 'mr/colorize-compilation-buffer)

(add-to-list 'display-buffer-alist
			 '("\\*compilation\\*"
			   (display-buffer-reuse-window display-buffer-at-bottom)
			   (reusable-frames . visible)
			   (window-height . 0.2)))

(defun mr/duplicate-line ()
  "Duplicates the current line."
  (interactive)
  (let ((column (- (point) (line-beginning-position)))
		(line (let ((s (thing-at-point 'line t)))
				(if s (string-remove-suffix "\n" s) ""))))
	(move-end-of-line 1)
	(newline)
	(insert line)
	(move-beginning-of-line 1)
	(forward-char column)))

(defun mr/save-and-kill-current-buffer ()
  "Saves the current buffer if modified, then kill it."
  (interactive)
  (if buffer-read-only
	  (progn
		(set-buffer-modified-p nil)
		(kill-current-buffer)
		(message "Read-only buffer killed; changes discarded."))
	(when (and (buffer-file-name) (buffer-modified-p))
	  (save-buffer))
	(kill-current-buffer)))

;; Compilation is driven by stock projectile commands (bound to F7/S-F7
;; below); these two globals carry over the only behaviors the old
;; `mr/compile-project' wrapper still added, now applied to *every*
;; compilation rather than just that one command.

;; `go test' and similar report error locations as bare filenames (each
;; package's test binary runs from its own directory). Let the *compilation*
;; buffer resolve those against any directory in the current project, so
;; next-error / clicks land on the right file. Set buffer-local to each
;; compilation, so it costs nothing outside a project.
(defun mr/compilation-project-search-path (_proc)
  (when-let* ((root (projectile-project-root)))
    (setq-local compilation-search-path
                (delete-dups
                 (mapcar (lambda (f) (file-name-directory (expand-file-name f root)))
                         (projectile-current-project-files))))))
(add-hook 'compilation-start-hook #'mr/compilation-project-search-path)

;; Give compilation subprocesses a color-capable TERM (the *compilation*
;; buffer is ANSI-colorized via `mr/colorize-compilation-buffer'). This is
;; the built-in per-compilation env knob, replacing an ad-hoc `setenv'.
(setq compilation-environment '("TERM=xterm-256color"))

(defun mr/move-lines (arg)
  "Move the current line, or all lines touched by the active region,
ARG lines forward (down) or backward (up). Snaps the moved span to
whole lines and keeps the region selected afterward so repeated calls
keep dragging the same block.

If a line's start is the region boundary, it's included on a fresh
selection (so e.g. landing on a closing brace via shift-down still
pulls that line in), but excluded when repeating this command
(`last-command'), since otherwise the boundary this command itself
leaves behind at a line start would get re-absorbed and the block
would grow by one line on every repeated press."
  (if (use-region-p)
	  (let* ((chaining (memq last-command '(mr/move-line-up mr/move-line-down)))
			 (point-at-end (> (point) (mark)))
			 (beg (min (point) (mark)))
			 (end (max (point) (mark))))
		(goto-char beg)
		(setq beg (line-beginning-position))
		(goto-char end)
		(setq end (if (and (bolp) (> end beg) chaining) end (line-beginning-position 2)))
		(when (and (< arg 0) (= beg (point-min)))
		  (user-error "Already at first line"))
		(when (and (> arg 0) (>= end (point-max)))
		  (user-error "Already at last line"))
		(let* ((text (delete-and-extract-region beg end))
			   (len (length text)))
		  (goto-char beg)
		  (forward-line arg)
		  (let ((new-beg (point)))
			(insert text)
			(if point-at-end
				(progn (set-mark new-beg) (goto-char (+ new-beg len)))
			  (progn (goto-char new-beg) (set-mark (+ new-beg len)))))
		  (setq deactivate-mark nil)))
	(let ((column (current-column)))
	  (beginning-of-line)
	  (when (or (> arg 0) (not (bobp)))
		(forward-line)
		(when (or (< arg 0) (not (eobp)))
		  (transpose-lines arg))
		(forward-line -1))
	  (move-to-column column))))

(defun mr/move-line-up ()
  "Move the current line, or the active region's lines, up one line."
  (interactive "*")
  (mr/move-lines -1))

(defun mr/move-line-down ()
  "Move the current line, or the active region's lines, down one line."
  (interactive "*")
  (mr/move-lines 1))

(global-set-key (kbd "C-,") 'mr/duplicate-line)
(global-set-key (kbd "M-<up>") 'mr/move-line-up)
(global-set-key (kbd "M-<down>") 'mr/move-line-down)
(global-set-key (kbd "C-x C-k") 'mr/save-and-kill-current-buffer)
;; F7 repeats the project's last command (compile/test/run); S-F7 starts a
;; fresh project compile -- which, for a CMake project with
;; `projectile-enable-cmake-presets', is the build-preset picker. Both are
;; stock projectile commands (also on C-c p C and C-c p c). On a project with
;; no history yet, F7 errors "No command has been run yet" -- press S-F7 once.
(global-set-key (kbd "<f7>") 'projectile-repeat-last-command)
(global-set-key (kbd "<S-f7>") 'projectile-compile-project)
(defun mr/project-create-file (path)
  "Create and visit a new file at PATH, relative to the current
project's root, creating any missing parent directories along the way."
  (interactive
   ;; `fussy-setup' overrides the `file' completion category to fuzzy-match
   ;; (pkgs.el), so a freshly typed path can fuzzy-match an existing file and
   ;; RET (`vertico-exit') silently opens that instead of creating PATH.
   ;; Disable fuzzy matching for just this prompt so what you type is what
   ;; you get; M-o/find-file elsewhere keep fuzzy matching.
   (list (let ((completion-styles '(basic partial-completion))
               (completion-category-overrides nil))
           (read-file-name "Create file: " (projectile-acquire-root)))))
  (make-directory (file-name-directory path) t)
  (find-file path))

(global-set-key (kbd "M-o") 'consult-projectile-find-file)
;; projectile-command-map only exists once projectile has loaded (pkgs.el, at
;; the end of init.el), so defer the binding until then. Puts create-file on
;; `C-c p n' / `s-p n', alongside the rest of projectile's project commands.
(with-eval-after-load 'projectile
  (define-key projectile-command-map "n" 'mr/project-create-file))

(defun mr/reload-init-file ()
  "Reload init.el."
  (interactive)
  (load-file user-init-file))
(global-set-key (kbd "C-c r") 'mr/reload-init-file)
(global-set-key (kbd "C-M-=") 'mr/increase-frame-font-size)
(global-set-key (kbd "C-M--") 'mr/decrease-frame-font-size)
(global-set-key (kbd "C-M-0") 'mr/reset-frame-font-size)

(with-eval-after-load 'dired
  (keymap-set dired-mode-map "_" 'dired-create-empty-file))

(require 'org)

(load-file "~/.config/emacs/pkgs.el")

