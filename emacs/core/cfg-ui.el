;; cfg-ui.el
;; by Matt Rudder (matt@mattrudder.com)

(load-theme 'wombat t)
(add-to-list 'default-frame-alist '(font . "Source Code Pro-13"))
(set-face-attribute 'default t :font "Source Code Pro-13")

(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(menu-bar-mode -1)

;; the blinking cursor is nothing, but an annoyance
(blink-cursor-mode -1)

;; disable startup screen
(setq inhibit-startup-screen t)

;; nice scrolling
(setq scroll-margin 0
      scroll-conservatively 100000
      scroll-preserve-screen-position 1)

;; mode line settings
(line-number-mode t)
(column-number-mode t)
(size-indication-mode t)

;; make the fringe (gutter) smaller
;; the argument is a width in pixels (the default is 8)
(if (fboundp 'fringe-mode)
    (fringe-mode 4))

;; enable y/n answers
(fset 'yes-or-no-p 'y-or-n-p)

;; more useful frame title, that show either a file or a
;; buffer name (if the buffer isn't visiting a file)
(setq frame-title-format
      '("" invocation-name " - " (:eval (if (buffer-file-name)
                                          (abbreviate-file-name (buffer-file-name))
                                          "%b"))))

(require 'desktop)
(setq desktop-save t)
(setq desktop-path (list config-savefile-dir))
(setq desktop-dirname config-savefile-dir)

(desktop-save-mode +1)

(provide 'cfg-ui)