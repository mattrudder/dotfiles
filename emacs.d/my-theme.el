;;; my-theme.el --- My visual editor settings
;;; Commentary:

;;; Code:
(setq custom-theme-directory "~/.emacs.d/themes")
(load-theme 'wombat-custom t)

(global-linum-mode)
(add-hook 'text-mode-hook (lambda() (linum-mode 0)))
(column-number-mode)

(provide 'my-theme)
;;; my-theme.el ends here
