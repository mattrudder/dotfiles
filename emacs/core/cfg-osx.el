;; cfg-osx.el
;; Mac OS X Specific settings
;; by Matt Rudder (matt@mattrudder.com)

(my:require-packages '(exec-path-from-shell))

(require 'exec-path-from-shell)
(exec-path-from-shell-initialize)

(setq ns-function-modifier 'hyper)
(defun my:swap-meta-and-super ()
  "Swap the mapping of Meta and Super.
Very useful for people using their Mac with a
Windows external keyboard from time to time."
  (interactive)
  (if (eq mac-command-modifier 'super)
      (progn
        (setq mac-command-modifier 'meta)
        (setq mac-option-modifier 'super)
        (message "Command is now bound to META and Option is bound to SUPER."))
    (progn
      (setq mac-command-modifier 'super)
      (setq mac-option-modifier 'meta)
      (message "Command is now bound to SUPER and Option is bound to META."))))

(global-set-key (kbd "C-c w") 'my:swap-meta-and-super)
(global-set-key (kbd "s-/") 'hippie-expand)

; Default to swap alt/cmd
(my:swap-meta-and-super)

(menu-bar-mode +1)

(provide 'cfg-osx)