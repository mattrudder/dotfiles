;; -*- lexical-binding: t; -*-
(setq custom-file "~/.emacs.d/custom.el")
(load-file custom-file)

(set-frame-font "Berkeley Mono 13" nil t)

(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(global-display-line-numbers-mode 1)

(ido-mode 1)
(ido-everywhere 1)

(load-file "~/.emacs.d/pkgs.el")
