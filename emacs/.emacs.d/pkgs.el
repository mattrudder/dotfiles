(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t) 
(package-initialize)

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(use-package ido-completing-read+
  :ensure t
  :config
  (ido-mode t)
  (ido-everywhere t)
  (setq ido-enable-flex-matching t)
  (setq ido-use-filename-at-point nil)
  (setq ido-use-virtual-buffers t))

(use-package smex
  :ensure t
  :config
  (smex-initialize))
