;;; -*- lexical-binding: t; -*-

(setq custom-file "~/.config/emacs/custom.el")
(load-file custom-file)

(set-frame-font "Berkeley Mono 13" nil t)

(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)

(global-display-line-numbers-mode 1)

(setq initial-buffer-choice (lambda () (dired default-directory)))

(when (eq system-type 'windows-nt)
  (setq shell-file-name "C:/Program Files/PowerShell/7/pwsh.exe")
  (setq shell-command-switch "-Command"))

(require 'ansi-color)
(defun mr/colorize-compilation-buffer ()
  (let ((inhibit-read-only t))
	(ansi-color-apply-on-region (point-min) (point-max))))

(add-hook 'compilation-filter-hook 'mr/colorize-compilation-buffer)

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

(defun mr/compile-project ()
  "Save project buffers and run compile. Prompt only if no command is set."
  (interactive)
  ;; Save all project-related buffers
  (let ((pr (project-current)))
	(when pr
	  (let ((buffers (project-buffers pr)))
		(dolist (buf buffers)
		  (with-current-buffer buf
			(when (and (buffer-file-name) (buffer-modified-p))
			  (save-buffer)))))))
  ;; Run compile, with prompt if compile-command is unset locally
  (setenv "TERM" "xterm-256color")  
  (let ((compilation-read-command
		 (not (local-variable-p 'compile-command))))
	(project-compile)))

(global-set-key (kbd "C-,") 'mr/duplicate-line)
(global-set-key (kbd "C-x C-k") 'mr/save-and-kill-current-buffer)
(global-set-key (kbd "<f7>") 'mr/compile-project)

(load-file "~/.config/emacs/pkgs.el")
