;;; -*- lexical-binding: t; -*-

(setq custom-file "~/.config/emacs/custom.el")
(load-file custom-file)

(defvar mr/frame-font-family "GohuFont 14 Nerd Font"
  "Font family used by `mr/set-frame-font-size'.")
(defconst mr/frame-font-default-size
  (cond
   ((eq system-type 'darwin) 18)
   ((eq system-type 'windows-nt) 14))
  "Point size `mr/reset-frame-font-size' restores.")
(defvar mr/frame-font-size mr/frame-font-default-size
  "Current point size used by `mr/set-frame-font-size'.")

(defun mr/set-frame-font-size (&optional frame)
  "Sets `mr/frame-font-family' at `mr/frame-font-size' to the FRAME
argument.  If FRAME is nil, apply to the selected frame. Always passes
an explicit size string to `set-frame-font', rather than relying on
face-height scaling, since that didn't reliably take effect."
  (interactive)
  (let ((font-str (format "%s %s" mr/frame-font-family mr/frame-font-size)))
	(setf (alist-get 'font default-frame-alist) font-str)
	
	(when (display-graphic-p frame)
	  (set-frame-font (format "%s %d" mr/frame-font-family mr/frame-font-size)
				   nil t))))

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

(defun mr/compile-project (&optional force-prompt)
  "Save project buffers and run compile. Prompt only if no command is
set, unless FORCE-PROMPT (e.g. a prefix arg) is non-nil."
  (interactive "P")
  (let ((pr (project-current)))
	;; Save all project-related buffers
	(when pr
	  (let ((buffers (project-buffers pr)))
		(dolist (buf buffers)
		  (with-current-buffer buf
			(when (and (buffer-file-name) (buffer-modified-p))
			  (save-buffer))))))
	;; Some tools (e.g. `go test') report error locations as a bare
	;; filename with no directory, since each package's test binary runs
	;; from its own directory. Populate `compilation-search-path' with
	;; every directory in the project so clicking those errors resolves
	;; the file directly instead of falling back to a "find file" prompt
	;; (which becomes a native file-open dialog for a mouse click).
	(when pr
	  (setq compilation-search-path
			(delete-dups (mapcar #'file-name-directory (project-files pr))))))
  ;; Run compile, with prompt only if compile-command is still the factory
  ;; default -- `compile' itself updates this via a plain (non-local) setq,
  ;; so comparing against (default-value ...) would always be trivially
  ;; equal; `standard-value' holds the defcustom's original form regardless
  ;; of later customization, whether from typing a command once or from a
  ;; project's .dir-locals.el.
  (setenv "TERM" "xterm-256color")
  (let ((compilation-read-command
		 (or force-prompt
			 (equal compile-command
					(eval (car (get 'compile-command 'standard-value)))))))
	(project-compile)))

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
(global-set-key (kbd "<f7>") 'mr/compile-project)
(global-set-key (kbd "<S-f7>") (lambda () (interactive) (mr/compile-project t)))
(defun mr/project-create-file (path)
  "Create and visit a new file at PATH, relative to the current
project's root, creating any missing parent directories along the way."
  (interactive
   (list (read-file-name "Create file: " (project-root (project-current t)))))
  (make-directory (file-name-directory path) t)
  (find-file path))

(global-set-key (kbd "M-o") 'project-find-file)
(define-key project-prefix-map "n" 'mr/project-create-file)
(global-set-key (kbd "C-M-=") 'mr/increase-frame-font-size)
(global-set-key (kbd "C-M--") 'mr/decrease-frame-font-size)
(global-set-key (kbd "C-M-0") 'mr/reset-frame-font-size)

(with-eval-after-load 'dired
  (keymap-set dired-mode-map "_" 'dired-create-empty-file))

(load-file "~/.config/emacs/pkgs.el")

