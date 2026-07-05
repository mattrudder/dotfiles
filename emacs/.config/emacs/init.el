;;; -*- lexical-binding: t; -*-

(setq custom-file "~/.config/emacs/custom.el")
(load-file custom-file)

(set-frame-font "Berkeley Mono 13" nil t)

(column-number-mode 1)

(global-display-line-numbers-mode 1)

(setq initial-buffer-choice (lambda () (dired default-directory)))

(when (eq system-type 'windows-nt)
  (setq shell-file-name "C:/Program Files/Git/usr/bin/bash.exe")
  (setq shell-command-switch "-lc"))

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
(global-set-key (kbd "M-o") 'project-find-file)
(global-set-key (kbd "M-i") 'imenu)

(with-eval-after-load 'dired
  (keymap-set dired-mode-map "_" 'dired-create-empty-file))

(load-file "~/.config/emacs/pkgs.el")
