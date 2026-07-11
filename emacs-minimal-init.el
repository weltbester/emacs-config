;;; init.el --- Minimal fallback Emacs config

(setq inhibit-startup-screen t)

(menu-bar-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(setq make-backup-files nil)
(setq auto-save-default nil)

(message "Loaded minimal fallback Emacs config")
