;;; init.el --- Emacs configuration  -*- lexical-binding: t -*-
;; lexical-binding: t enables lexical scoping — faster closures, required by
;; many modern packages.
;; Original config backed up as: ~/.emacs.d/init.el.bak

;;; ============================================================
;;; 1. STARTUP
;;; ============================================================

(setq inhibit-startup-message t)    ; skip the welcome screen

(scroll-bar-mode -1)                ; disable GUI scrollbar
(tool-bar-mode   -1)                ; disable icon toolbar
(menu-bar-mode    1)                ; keep menu bar (macOS convention)
(tooltip-mode    -1)                ; disable hover tooltips
(set-fringe-mode 10)                ; add breathing room at frame edges

(setq visible-bell t)               ; flash instead of audible bell

;; Async byte-compilation warnings clutter the echo area — silence them.
(setq native-comp-async-report-warnings-errors nil)

;;; ============================================================
;;; 2. PACKAGE MANAGEMENT
;;; ============================================================

(require 'package)

;; MELPA for up-to-date packages; orgmode.org/elpa for org; gnu elpa as fallback.
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("org"   . "https://orgmode.org/elpa/")
        ("elpa"  . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Bootstrap use-package if not yet installed.
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
;; Auto-install every package declared with use-package.
(setq use-package-always-ensure t)

;;; ============================================================
;;; 3. FONTS
;;; Install with: brew install --cask font-fira-code font-cantarell
;;; ============================================================

;; Monospace font for code and the default face.
(set-face-attribute 'default nil
                    :font "Fira Code Retina"
                    :height 160)

;; fixed-pitch must match default so mixed-pitch modes look consistent.
(set-face-attribute 'fixed-pitch nil
                    :font "Fira Code Retina"
                    :height 160)

;; variable-pitch is used in org-mode for prose text.
(set-face-attribute 'variable-pitch nil
                    :font "Cantarell"
                    :height 165
                    :weight 'regular)

;;; ============================================================
;;; 4. THEME
;;; ============================================================

;; deeper-blue is a built-in dark theme — no extra package needed.
;; The t argument suppresses the "safe theme?" confirmation prompt.
(load-theme 'deeper-blue t)

;;; ============================================================
;;; 5. macOS SETTINGS
;;; ============================================================

(when (eq system-type 'darwin)
  ;; ⌘ (Command) acts as Meta so standard Emacs bindings work.
  ;; Both Option keys are set to none so macOS dead-key input still works
  ;; and ⌥-x produces ≈ which we bind to execute-extended-command below.
  (setq mac-command-modifier      'meta
        mac-option-modifier       'none
        mac-right-option-modifier 'none)
  (global-set-key [kp-delete] 'delete-char)) ; fn-Delete = forward-delete

;; Remap to macOS-style shortcuts (⌘ = Meta after the setting above).
;; M-x is kill-region (⌘-x = Cut); use ≈ (⌥-x) for execute-extended-command.
(global-set-key (kbd "M-c") #'kill-ring-save)          ; ⌘-c  Copy
(global-set-key (kbd "M-x") #'kill-region)              ; ⌘-x  Cut
(global-set-key (kbd "M-v") #'yank)                     ; ⌘-v  Paste
(global-set-key (kbd "M-a") #'mark-whole-buffer)        ; ⌘-a  Select all
(global-set-key (kbd "M-z") #'undo)                     ; ⌘-z  Undo
(global-set-key (kbd "≈")   #'execute-extended-command) ; ⌥-x  Command palette

;; On macOS, GUI Emacs does not inherit the shell PATH, so language servers
;; (clangd, rust-analyzer, pylsp) would not be found without this package.
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :init (exec-path-from-shell-initialize))

;;; ============================================================
;;; 6. CORE EDITING
;;; ============================================================

(setq-default fill-column      81   ; column used by auto-fill and indicators
              indent-tabs-mode nil  ; spaces only
              tab-width        4)

(column-number-mode               1) ; show column number in modeline
(global-display-line-numbers-mode 1) ; line numbers in every buffer
(global-hl-line-mode              1) ; highlight the current line
(blink-cursor-mode                1) ; blinking cursor
(electric-pair-mode               1) ; auto-close brackets, quotes, etc.
(delete-selection-mode            1) ; typing replaces the active selection
(global-auto-revert-mode          1) ; reload files changed on disk
(savehist-mode                    1) ; persist minibuffer history across sessions
(recentf-mode                     1) ; track recently opened files for consult

;; Line numbers are distracting in terminal, org and shell buffers.
(dolist (mode '(org-mode-hook
                term-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; Highlight characters past column 80 in red so long lines are obvious.
(use-package column-enforce-mode
  :hook (prog-mode . column-enforce-mode))

;; UTF-8 as the universal encoding to avoid surprises with special characters.
(set-language-environment    "UTF-8")
(prefer-coding-system        'utf-8)
(set-terminal-coding-system  'utf-8)
(setq select-enable-clipboard t)    ; sync kill-ring with macOS clipboard

;;; ============================================================
;;; 7. UI PACKAGES
;;; ============================================================

;; Nerd-icons supplies the glyphs used by doom-modeline.
;; Run once after first install: M-x nerd-icons-install-fonts
(use-package nerd-icons)

;; Informative modeline showing mode, branch, LSP status, etc.
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom (doom-modeline-height 15))

;; Color-code matching bracket pairs by nesting depth.
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Show available key completions after a short pause (discovery aid).
(use-package which-key
  :diminish which-key-mode
  :init (which-key-mode 1)
  :config (setq which-key-idle-delay 0.5))

;; Richer help buffers with source links and examples.
(use-package helpful
  :bind
  ([remap describe-function] . helpful-callable)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-command]  . helpful-command)
  ([remap describe-key]      . helpful-key))

;;; ============================================================
;;; 8. COMPLETION — Vertico + Consult + Orderless + Marginalia
;;; ============================================================

;; Vertical list UI for the minibuffer (replaces Ivy).
(use-package vertico
  :init (vertico-mode 1))

;; Match candidates by space-separated components in any order.
(use-package orderless
  :custom
  (completion-styles             '(orderless basic))
  (completion-category-defaults  nil)
  ;; Files still use partial-completion so /usr/lo/b expands correctly.
  (completion-category-overrides '((file (styles partial-completion)))))

;; Annotations next to candidates (file size, doc string excerpt, etc.).
(use-package marginalia
  :init (marginalia-mode 1))

;; Practical commands built on completing-read with live preview.
(use-package consult
  :bind (("C-s"   . consult-line)    ; incremental search in buffer
         ("C-x b" . consult-buffer)  ; switch buffer with preview
         ("M-y"   . consult-yank-pop); browse kill-ring
         ("C-M-j" . consult-buffer)))

;; Popup completion-at-point UI — integrates with eglot automatically.
(use-package corfu
  :custom
  (corfu-auto            t)    ; show popup without explicit trigger
  (corfu-auto-delay      0.2)  ; seconds before popup appears
  (corfu-quit-at-boundary 'separator)
  :init (global-corfu-mode 1))

;;; ============================================================
;;; 9. PROGRAMMING
;;; ============================================================

;; --- LSP via eglot (built into Emacs 29+) -------------------
;; Language servers must be installed once:
;;   C/C++:  brew install llvm    → clangd
;;   Python: brew install python-lsp-server  → pylsp
;;   Rust:   rustup component add rust-analyzer
(use-package eglot
  :ensure nil  ; built-in — do not fetch from MELPA
  :hook ((c-mode      . eglot-ensure)
         (c++-mode    . eglot-ensure)
         (python-mode . eglot-ensure)
         (rust-mode   . eglot-ensure))
  :config
  ;; Kill the LSP server when its last buffer is closed.
  (setq eglot-autoshutdown t)
  ;; pyright scans the entire project tree on startup, which freezes Emacs
  ;; on large Nextcloud directories. pylsp analyses only open files.
  (add-to-list 'eglot-server-programs
               '(python-mode . ("pylsp"))))

;; --- Rust ----------------------------------------------------
;; rust-mode provides cargo commands, rustfmt, and .rs file detection.
(use-package rust-mode
  :mode "\\.rs\\'")

;; --- Python --------------------------------------------------
;; 4-space indentation, no tabs — PEP 8 convention.
(add-hook 'python-mode-hook
          (lambda ()
            (setq indent-tabs-mode       nil
                  tab-width              4
                  python-indent-offset   4)))

;; --- C / C++ -------------------------------------------------
;; 4-space indentation, no tabs — matches most open-source C style guides.
(add-hook 'c-mode-common-hook
          (lambda ()
            (setq indent-tabs-mode nil
                  c-basic-offset   4)))

;;; ============================================================
;;; 10. ORG-MODE
;;; ============================================================

(defun my/org-mode-setup ()
  (org-indent-mode)       ; indent body text under its heading
  (variable-pitch-mode 1) ; use Cantarell for prose
  (visual-line-mode 1))   ; soft-wrap long lines without inserting newlines

(defun my/org-font-setup ()
  ;; Scale heading levels — larger = more prominent hierarchy.
  (dolist (face '((org-level-1 . 1.2)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)))
    (set-face-attribute (car face) nil
                        :font   "Cantarell"
                        :weight 'regular
                        :height (cdr face)))
  ;; Code blocks, tables and keywords must stay in fixed-pitch even when
  ;; variable-pitch-mode is active, otherwise columns won't align.
  (set-face-attribute 'org-block           nil :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code            nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table           nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim        nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line       nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox        nil :inherit 'fixed-pitch))

(use-package org
  :hook (org-mode . my/org-mode-setup)
  :config
  (setq org-ellipsis                  " ▾" ; collapsed heading indicator
        org-hide-emphasis-markers      t    ; hide *bold* / /italic/ markers
        org-agenda-start-with-log-mode t    ; show done items in agenda log
        org-log-done                   'time ; timestamp when a TODO is closed
        org-log-into-drawer            t    ; keep log entries in LOGBOOK drawer
        org-agenda-files
        '("~/Nextcloud/org-mode/Task.org"
          "~/Nextcloud/org-mode/Birthday.org"))
  (my/org-font-setup))

;; Replace plain * bullets with unicode symbols for readability.
(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

(defun my/org-visual-fill ()
  ;; Center org buffers with margins so long lines don't span the full frame.
  (setq visual-fill-column-width       100
        visual-fill-column-center-text  t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . my/org-visual-fill))

;; Export current org file to PDF via LaTeX and open the result.
;; Requires LaTeX: brew install --cask mactex
(defun my/org-export-as-pdf ()
  (interactive)
  (save-buffer)
  (org-open-file (org-latex-export-to-pdf)))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "<f5>") #'my/org-export-as-pdf))

;;; ============================================================
;;; 11. GIT — Magit
;;; ============================================================

;; C-x g opens the Magit status buffer from any buffer.
(use-package magit
  :commands magit-status
  :bind ("C-x g" . magit-status))

;;; ============================================================
;;; 12. FULLSCREEN ON STARTUP (iMac)
;;; To enable: uncomment the three lines marked ENABLE
;;; ============================================================

;; On macOS, native full-screen moves Emacs to a separate Space,
;; which causes left/right sliding bugs when calling make-frame.
;; The workaround: start maximized, then switch to full-screen
;; after 5 seconds — macOS keeps it in the current Space.

(setq ns-use-native-fullscreen nil)    ; ENABLE
(setq ns-use-fullscreen-animation nil) ; ENABLE
(run-at-time "5sec" nil                ; ENABLE
             (lambda ()
               (let ((fullscreen (frame-parameter (selected-frame)
                                                  'fullscreen)))
                 (when (memq fullscreen '(fullscreen fullboth))
                   (set-frame-parameter (selected-frame)
                                        'fullscreen 'maximized))
                 (sleep-for 0.5)
                 (toggle-frame-fullscreen))))

;;; init.el ends here
