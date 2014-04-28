;; init.el
;; Chock-full of good stuff
;; by Matt Rudder (matt@mattrudder.com)

(defvar current-user
      (getenv
        (if (equal system-type 'windows-nt) "USERNAME" "USER")))

;; Always load newest byte code
(setq load-prefer-newer t)

(defvar config-dir (file-name-directory load-file-name)
  "The root dir of the Emacs configuration.")
(defvar config-core-dir (expand-file-name "core" config-dir)
  "The home of Emacs core configuration.")
(defvar config-local-dir (expand-file-name "local" config-dir)
  "This directory is for your personal configuration, local to this machine.")
(defvar config-savefile-dir (expand-file-name "savefile" config-dir)
  "This folder stores all the automatically generated save/history-files.")
(defvar config-vendor-dir (expand-file-name "vendor" config-dir)
  "This folder stores all packages not retrieved from package.el.")

(defun my:add-subfolders-to-load-path (parent-dir)
 "Add all level PARENT-DIR subdirs to the `load-path'."
 (add-to-list 'load-path parent-dir)
 (dolist (f (directory-files parent-dir))
   (let ((name (expand-file-name f parent-dir)))
     (when (and (file-directory-p name)
                (not (equal f ".."))
                (not (equal f ".")))
       (add-to-list 'load-path name)
       (my:add-subfolders-to-load-path name)))))

(unless (file-exists-p config-savefile-dir)
  (make-directory config-savefile-dir))
(unless (file-exists-p config-local-dir)
  (make-directory config-local-dir))

(my:add-subfolders-to-load-path config-core-dir)
(my:add-subfolders-to-load-path config-local-dir)
(message "Loading vendor path %s..." config-vendor-dir)
(add-to-list 'load-path config-vendor-dir)

(setq gc-cons-threshold 50000000)

(require 'cfg-packages)
(require 'cfg-ui)
;(require 'cfg-core)
;(require 'cfg-modes)
(require 'cfg-editor)
(require 'cfg-keybindings)

;; OSX specific settings
(when (eq system-type 'darwin)
  (require 'cfg-osx))

(setq custom-file (expand-file-name "custom.el" config-local-dir))

;; load the personal settings (this includes `custom-file')
(when (file-exists-p config-local-dir)
  (message "Loading local configuration files in %s..." config-local-dir)
  (mapc 'load (directory-files config-local-dir 't "^[^#].*el$")))
