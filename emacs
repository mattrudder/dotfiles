; ~/.emacs
(load "~/.emacs.d/my-theme.el")
(add-hook 'after-init-hook '(lambda ()
  (load "~/.emacs.d/my-noexternals.el")
))

(load "~/.emacs.d/my-loadpackages.el")
