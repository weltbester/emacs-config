;;; init.el --- Power-user Emacs config placeholder

(setq inhibit-startup-screen t)

(message "Loaded power-user Emacs config placeholder")

;;; init.el --- Power-user Emacs base config

;;; Basic startup behavior

(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; macOS behavior

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta)
  (setq mac-option-modifier 'none)
  (setq ns-function-modifier 'hyper)
  (setq ns-use-native-fullscreen t))

;;; Backups and autosaves

(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups/" user-emacs-directory))))

(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-save/" user-emacs-directory) t)))

(make-directory (expand-file-name "backups/" user-emacs-directory) t)
(make-directory (expand-file-name "auto-save/" user-emacs-directory) t)

;;; Package management

(require 'package)

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)

(setq use-package-always-ensure t)
(setq use-package-always-defer t)
(setq use-package-verbose nil)

;;; macOS shell environment import

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :demand t
  :config
  (setq exec-path-from-shell-variables
        '("PATH" "MANPATH" "SHELL" "LANG" "LC_ALL" "LC_CTYPE"))
  (exec-path-from-shell-initialize))

;;; General editing defaults

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq require-final-newline t)
(setq ring-bell-function 'ignore)

(global-display-line-numbers-mode 1)
(column-number-mode 1)
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)

(setq recentf-max-saved-items 200)
(setq history-length 200)

(show-paren-mode 1)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

;;; Built-in project support

(use-package project
  :ensure nil
  :defer nil)

(message "Loaded power-user Emacs base config")

;;; ---------------------------------------------------------------------------
;;; Completion and navigation
;;; ---------------------------------------------------------------------------

(use-package vertico
  :demand t
  :config
  (vertico-mode 1))

(use-package orderless
  :demand t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :demand t
  :config
  (marginalia-mode 1))

(use-package consult
  :bind
  (("C-s" . consult-line)
   ("C-x b" . consult-buffer)
   ("C-c f" . consult-find)
   ("C-c g" . consult-grep)
   ("C-c r" . consult-ripgrep)
   ("C-c i" . consult-imenu)
   ("C-c p b" . consult-project-buffer)))

(use-package corfu
  :demand t
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.2
        corfu-auto-prefix 2
        corfu-cycle t
        corfu-preview-current nil)
  (global-corfu-mode 1))

(use-package cape
  :after corfu
  :config
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package which-key
  :demand t
  :config
  (setq which-key-idle-delay 0.5)
  (which-key-mode 1))

(use-package helpful
  :bind
  (("C-h f" . helpful-callable)
   ("C-h v" . helpful-variable)
   ("C-h k" . helpful-key)
   ("C-h x" . helpful-command)))

(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind
  (:map vertico-map
        ("DEL" . vertico-directory-delete-char)
        ("M-DEL" . vertico-directory-delete-word)
        ("C-l" . vertico-directory-up))
  :hook
  (rfn-eshadow-update-overlay . vertico-directory-tidy))

(message "Loaded completion/navigation configuration")

;;; ---------------------------------------------------------------------------
;;; Programming foundation: Tree-sitter, Eglot, C/C++, Python, Rust
;;; ---------------------------------------------------------------------------

(setq treesit-language-source-alist
      '((bash   "https://github.com/tree-sitter/tree-sitter-bash")
        (c      "https://github.com/tree-sitter/tree-sitter-c")
        (cpp    "https://github.com/tree-sitter/tree-sitter-cpp")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (rust   "https://github.com/tree-sitter/tree-sitter-rust")
        (toml   "https://github.com/tree-sitter/tree-sitter-toml")
        (json   "https://github.com/tree-sitter/tree-sitter-json")
        (yaml   "https://github.com/ikatyang/tree-sitter-yaml")))

(defun gp/treesit-install-missing-grammars ()
  "Install missing Tree-sitter grammars from `treesit-language-source-alist'."
  (interactive)
  (dolist (grammar treesit-language-source-alist)
    (let ((lang (car grammar)))
      (unless (treesit-language-available-p lang)
        (message "Installing Tree-sitter grammar: %s" lang)
        (treesit-install-language-grammar lang)))))

(when (fboundp 'c-ts-mode)
  (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode)))

(when (fboundp 'c++-ts-mode)
  (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode)))

(when (fboundp 'python-ts-mode)
  (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))

(when (fboundp 'rust-ts-mode)
  (add-to-list 'major-mode-remap-alist '(rust-mode . rust-ts-mode)))

(use-package rust-mode
  :mode "\\.rs\\'"
  :hook
  (rust-mode . eglot-ensure)
  :config
  (setq rust-format-on-save nil))

(when (fboundp 'rust-ts-mode)
  (add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))
  (add-hook 'rust-ts-mode-hook #'eglot-ensure))

(use-package eglot
  :ensure nil
  :hook
  ((c-mode c-ts-mode c++-mode c++-ts-mode python-mode python-ts-mode rust-mode rust-ts-mode)
   . eglot-ensure)
  :bind
  (:map eglot-mode-map
        ("C-c l r" . eglot-rename)
        ("C-c l a" . eglot-code-actions)
        ("C-c l f" . eglot-format)
        ("C-c l d" . eldoc)
        ("C-c l i" . eglot-find-implementation)
        ("C-c l t" . eglot-find-typeDefinition))
  :config
  (setq eglot-events-buffer-size 0)
  (setq eglot-autoshutdown t)

  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode c++-mode c++-ts-mode)
                 . ("/opt/homebrew/opt/llvm/bin/clangd"
                    "--background-index"
                    "--clang-tidy"
                    "--completion-style=detailed"
                    "--header-insertion=iwyu")))

  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . ("pyright-langserver" "--stdio")))

  (add-to-list 'eglot-server-programs
               '((rust-mode rust-ts-mode)
                 . ("/opt/homebrew/opt/rustup/bin/rust-analyzer"))))

(defun gp/c-cpp-common-setup ()
  "Common C/C++ editing defaults."
  (setq-local c-basic-offset 4)
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode nil))

(add-hook 'c-mode-hook #'gp/c-cpp-common-setup)
(add-hook 'c++-mode-hook #'gp/c-cpp-common-setup)
(add-hook 'c-ts-mode-hook #'gp/c-cpp-common-setup)
(add-hook 'c++-ts-mode-hook #'gp/c-cpp-common-setup)

(defun gp/python-setup ()
  "Python editing defaults."
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode nil))

(add-hook 'python-mode-hook #'gp/python-setup)
(add-hook 'python-ts-mode-hook #'gp/python-setup)

(defun gp/rust-setup ()
  "Rust editing defaults."
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode nil))

(add-hook 'rust-mode-hook #'gp/rust-setup)
(add-hook 'rust-ts-mode-hook #'gp/rust-setup)

(use-package flymake
  :ensure nil
  :defer nil
  :bind
  (("C-c ! l" . flymake-show-buffer-diagnostics)
   ("C-c ! n" . flymake-goto-next-error)
   ("C-c ! p" . flymake-goto-prev-error)))

(defun gp/format-buffer-with-eglot ()
  "Format current buffer via Eglot if available."
  (interactive)
  (if (bound-and-true-p eglot--managed-mode)
      (eglot-format-buffer)
    (message "Current buffer is not managed by Eglot")))

(global-set-key (kbd "C-c l F") #'gp/format-buffer-with-eglot)

(message "Loaded programming/LSP configuration")

;;; ---------------------------------------------------------------------------
;;; Org-mode setup
;;; ---------------------------------------------------------------------------

(use-package org
  :ensure nil
  :defer nil
  :mode ("\\.org\\'" . org-mode)
  :bind
  (("C-c o a" . org-agenda)
   ("C-c o c" . org-capture)
   ("C-c o l" . org-store-link)
   ("C-c o n" . gp/open-org-notes)
   ("C-c o t" . gp/open-org-tasks)
   ("C-c o p" . gp/open-org-ai-prompts))
  :config
  (setq org-directory (expand-file-name "~/org"))
  (setq org-default-notes-file (expand-file-name "notes.org" org-directory))

  (setq org-agenda-files
        (list (expand-file-name "tasks.org" org-directory)
              (expand-file-name "notes.org" org-directory)
              (expand-file-name "projects" org-directory)))

  (setq org-startup-indented t)
  (setq org-hide-emphasis-markers t)
  (setq org-return-follows-link t)
  (setq org-log-done 'time)
  (setq org-use-speed-commands t)
  (setq org-confirm-babel-evaluate nil)

  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "WAIT(w@/!)" "|" "DONE(d)" "CANCELLED(c@)")))

  (setq org-log-into-drawer t)
  (setq org-archive-location
        (expand-file-name "archive/%s_archive::" org-directory))

  (setq org-src-preserve-indentation nil)
  (setq org-edit-src-content-indentation 0)
  (setq org-src-tab-acts-natively t)
  (setq org-src-fontify-natively t)

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((C . t)
     (python . t)
     (shell . t)
     (emacs-lisp . t)))

  (setq org-capture-templates
        '(("t" "Task" entry
           (file "~/org/tasks.org")
           "* TODO %?\n  CREATED: %U\n")

          ("n" "Note" entry
           (file "~/org/notes.org")
           "* %?\n  CREATED: %U\n")

          ("p" "AI Prompt" entry
           (file "~/org/ai/prompts.org")
           "* %^{Title}\n  CREATED: %U\n\n** Context\n%?\n\n** Prompt\n\n** Result\n\n** Follow-up\n"))))

(defun gp/open-org-notes ()
  "Open main Org notes file."
  (interactive)
  (find-file (expand-file-name "~/org/notes.org")))

(defun gp/open-org-tasks ()
  "Open main Org tasks file."
  (interactive)
  (find-file (expand-file-name "~/org/tasks.org")))

(defun gp/open-org-ai-prompts ()
  "Open AI prompt Org file."
  (interactive)
  (find-file (expand-file-name "~/org/ai/prompts.org")))

(use-package ob-rust
  :after org
  :demand t
  :config
  (let ((rustup-bin "/opt/homebrew/opt/rustup/bin")
        (cargo-bin (expand-file-name "~/.cargo/bin")))
    (dolist (dir (list rustup-bin cargo-bin))
      (when (file-directory-p dir)
        (setenv "PATH" (concat dir path-separator (getenv "PATH")))
        (add-to-list 'exec-path dir))))

  (add-to-list 'org-babel-load-languages '(rust . t))
  (org-babel-do-load-languages
   'org-babel-load-languages
   org-babel-load-languages)

  (setq org-babel-default-header-args:rust
        '((:results . "output replace")
          (:exports . "both"))))

(with-eval-after-load 'org
  (setq org-babel-python-command "python3")
  (setq org-babel-default-header-args:python
        '((:results . "output replace")
          (:exports . "both")))
  (setq org-babel-C-compiler "/opt/homebrew/opt/llvm/bin/clang")
  (setq org-babel-C++-compiler "/opt/homebrew/opt/llvm/bin/clang++"))

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-star 'replace)
  (setq org-modern-table nil))

(message "Loaded Org-mode configuration")

;;; ---------------------------------------------------------------------------
;;; Org-mode PDF export via LaTeX
;;; ---------------------------------------------------------------------------

;;; Falls Emacs =latexmk= oder =lualatex= nicht findet, zusätzlich den TeX-Pfad ergänzen:

(when (eq system-type 'darwin)
  (let ((texbin "/Library/TeX/texbin"))
    (when (file-directory-p texbin)
      (setenv "PATH" (concat texbin path-separator (getenv "PATH")))
      (add-to-list 'exec-path texbin))))

(with-eval-after-load 'ox-latex
  (setq org-latex-compiler "lualatex")
  (setq org-latex-pdf-process
        '("latexmk -lualatex -shell-escape -interaction=nonstopmode -f %f")))

(message "Loaded Org PDF export configuration")

;;; ---------------------------------------------------------------------------
;;; AI workflow support: vterm, Codex, Claude Code, Magit
;;; ---------------------------------------------------------------------------

(use-package vterm
  :commands (vterm)
  :config
  (setq vterm-max-scrollback 20000)
  (setq vterm-shell (or (getenv "SHELL") "/bin/zsh")))

(defun gp/project-root-or-default ()
  "Return current project root or `default-directory'."
  (if-let ((project (project-current)))
      (project-root project)
    default-directory))

(defun gp/vterm-in-project (buffer-name &optional command)
  "Open vterm in current project root.
If COMMAND is non-nil, send it to the terminal."
  (interactive)
  (let ((default-directory (gp/project-root-or-default)))
    (vterm buffer-name)
    (when command
      (vterm-send-string command)
      (vterm-send-return))))

(defun gp/ai-codex ()
  "Start Codex CLI in a vterm at the current project root."
  (interactive)
  (gp/vterm-in-project "*ai-codex*" "codex"))

(defun gp/ai-claude ()
  "Start Claude Code in a vterm at the current project root."
  (interactive)
  (gp/vterm-in-project "*ai-claude*" "claude"))

(defun gp/ai-shell ()
  "Open a plain AI work shell in a vterm at the current project root."
  (interactive)
  (gp/vterm-in-project "*ai-shell*"))

(defun gp/open-ai-prompts ()
  "Open main AI prompts Org file."
  (interactive)
  (find-file (expand-file-name "~/org/ai/prompts.org")))

(defun gp/new-ai-session-note ()
  "Create a timestamped AI session note."
  (interactive)
  (let* ((ts (format-time-string "%Y%m%d-%H%M%S"))
         (file (expand-file-name
                (format "~/org/ai/sessions/session-%s.org" ts))))
    (find-file file)
    (insert "#+title: AI Session " ts "\n")
    (insert "#+created: " (format-time-string "%Y-%m-%d %H:%M:%S %z") "\n\n")
    (insert "* Context\n\n")
    (insert "* Prompt\n\n")
    (insert "* Result\n\n")
    (insert "* Review\n\n")))

(defun gp/copy-region-or-buffer-for-ai ()
  "Copy active region, or whole buffer if no region is active, to kill ring."
  (interactive)
  (if (use-region-p)
      (progn
        (kill-ring-save (region-beginning) (region-end))
        (message "Copied region for AI"))
    (progn
      (kill-ring-save (point-min) (point-max))
      (message "Copied whole buffer for AI"))))

(use-package magit
  :commands (magit-status magit-diff-buffer-file magit-log-buffer-file)
  :bind
  (("C-c m s" . magit-status)
   ("C-c m d" . magit-diff-buffer-file)
   ("C-c m l" . magit-log-buffer-file)))

(global-set-key (kbd "C-c a c") #'gp/ai-codex)
(global-set-key (kbd "C-c a C") #'gp/ai-claude)
(global-set-key (kbd "C-c a s") #'gp/ai-shell)
(global-set-key (kbd "C-c a p") #'gp/open-ai-prompts)
(global-set-key (kbd "C-c a n") #'gp/new-ai-session-note)
(global-set-key (kbd "C-c a y") #'gp/copy-region-or-buffer-for-ai)

(message "Loaded AI workflow configuration")

;;; ---------------------------------------------------------------------------
;;; Custom dark no-magenta theme, fonts, Org readability, 80-column overflow
;;; ---------------------------------------------------------------------------

(defun gp/font-available-p (font-name)
  "Return non-nil if FONT-NAME is available."
  (member font-name (font-family-list)))

(defun gp/first-available-font (&rest fonts)
  "Return first available font from FONTS."
  (seq-find #'gp/font-available-p fonts))

(defun gp/setup-fonts ()
  "Configure coding and text fonts."
  (let ((code-font (gp/first-available-font
                    "JetBrainsMono Nerd Font Mono"
                    "JetBrainsMono Nerd Font"
                    "JetBrains Mono"
                    "Menlo"
                    "Monaco"))
        (text-font (gp/first-available-font
                    "Avenir Next"
                    "Helvetica Neue"
                    "Helvetica")))
    (when code-font
      (set-face-attribute 'default nil
                          :family code-font
                          :height 145
                          :weight 'regular)
      (set-face-attribute 'fixed-pitch nil
                          :family code-font
                          :height 145
                          :weight 'regular))
    (when text-font
      (set-face-attribute 'variable-pitch nil
                          :family text-font
                          :height 155
                          :weight 'regular))))

(gp/setup-fonts)

(defun gp/apply-no-magenta-dark-theme ()
  "Apply a dark coding theme without purple/magenta colors."
  (interactive)
  (require 'whitespace nil t)
  (require 'hl-line nil t)
  (mapc #'disable-theme custom-enabled-themes)

  (set-face-attribute 'default nil :background "#0f1419" :foreground "#d8dee9")
  (set-face-attribute 'cursor nil :background "#88c0d0")
  (set-face-attribute 'fringe nil :background "#0f1419")
  (set-face-attribute 'region nil :background "#2f3b4a")
  (set-face-attribute 'highlight nil :background "#243447")
  (when (facep 'hl-line)
    (set-face-attribute 'hl-line nil :background "#18222f" :extend t))
  (set-face-attribute 'minibuffer-prompt nil :foreground "#88c0d0" :weight 'bold)

  (set-face-attribute 'line-number nil :foreground "#4c566a" :background "#0f1419")
  (set-face-attribute 'line-number-current-line nil :foreground "#eceff4" :background "#18222f" :weight 'bold)

  (set-face-attribute 'font-lock-comment-face nil :foreground "#6b7280" :slant 'italic)
  (set-face-attribute 'font-lock-doc-face nil :foreground "#7f8c98" :slant 'italic)
  (set-face-attribute 'font-lock-keyword-face nil :foreground "#81a1c1" :weight 'bold)
  (set-face-attribute 'font-lock-builtin-face nil :foreground "#88c0d0")
  (set-face-attribute 'font-lock-function-name-face nil :foreground "#88c0d0" :weight 'bold)
  (set-face-attribute 'font-lock-variable-name-face nil :foreground "#d8dee9")
  (set-face-attribute 'font-lock-type-face nil :foreground "#ebcb8b" :weight 'bold)
  (set-face-attribute 'font-lock-constant-face nil :foreground "#d08770")
  (set-face-attribute 'font-lock-string-face nil :foreground "#a3be8c")
  (set-face-attribute 'font-lock-preprocessor-face nil :foreground "#5e81ac" :weight 'bold)
  (set-face-attribute 'font-lock-warning-face nil :foreground "#ff6b6b" :background "#3a1f1f" :weight 'bold)

  (set-face-attribute 'flymake-error nil :underline '(:style wave :color "#ff6b6b"))
  (set-face-attribute 'flymake-warning nil :underline '(:style wave :color "#ebcb8b"))
  (set-face-attribute 'flymake-note nil :underline '(:style wave :color "#88c0d0"))

  (set-face-attribute 'match nil :background "#2e4a3f" :foreground "#e5e9f0" :weight 'bold)
  (set-face-attribute 'isearch nil :background "#ebcb8b" :foreground "#0f1419" :weight 'bold)
  (set-face-attribute 'lazy-highlight nil :background "#3b4252" :foreground "#eceff4")

  (when (facep 'whitespace-line)
    (set-face-attribute 'whitespace-line nil
                        :background "#5f0000"
                        :foreground "#ffb3b3"
                        :weight 'bold))

  (with-eval-after-load 'org
    (set-face-attribute 'org-level-1 nil :foreground "#88c0d0" :weight 'bold :height 1.25)
    (set-face-attribute 'org-level-2 nil :foreground "#81a1c1" :weight 'bold :height 1.15)
    (set-face-attribute 'org-level-3 nil :foreground "#a3be8c" :weight 'bold :height 1.08)
    (set-face-attribute 'org-level-4 nil :foreground "#ebcb8b" :weight 'bold :height 1.03)
    (set-face-attribute 'org-block nil :background "#111827" :foreground "#d8dee9" :inherit 'fixed-pitch)
    (set-face-attribute 'org-block-begin-line nil :background "#1f2937" :foreground "#7f8c98" :inherit 'fixed-pitch)
    (set-face-attribute 'org-block-end-line nil :background "#1f2937" :foreground "#7f8c98" :inherit 'fixed-pitch)
    (set-face-attribute 'org-code nil :foreground "#a3be8c" :inherit 'fixed-pitch)
    (set-face-attribute 'org-verbatim nil :foreground "#ebcb8b" :inherit 'fixed-pitch)))

(gp/apply-no-magenta-dark-theme)
(global-hl-line-mode 1)

(use-package whitespace
  :ensure nil
  :config
  (setq whitespace-style '(face lines-tail))
  (setq whitespace-line-column 80)
  (set-face-attribute 'whitespace-line nil
                      :background "#5f0000"
                      :foreground "#ffb3b3"
                      :weight 'bold))

(defun gp/code-visual-line-length-mode ()
  "Highlight only characters beyond column 80 in code buffers.
Do not show a vertical fill-column ruler."
  (setq-local fill-column 80)
  (setq-local whitespace-style '(face lines-tail))
  (setq-local whitespace-line-column 80)
  (when (bound-and-true-p display-fill-column-indicator-mode)
    (display-fill-column-indicator-mode -1))
  (whitespace-mode 1))

(add-hook 'prog-mode-hook #'gp/code-visual-line-length-mode)

(defun gp/org-visual-setup ()
  "Improve Org readability while preserving fixed-pitch code areas."
  (variable-pitch-mode 1)
  (visual-line-mode 1)
  (dolist (face '(org-block
                  org-block-begin-line
                  org-block-end-line
                  org-code
                  org-verbatim
                  org-table
                  org-meta-line
                  org-property-value
                  org-special-keyword
                  org-drawer
                  org-date
                  org-checkbox))
    (set-face-attribute face nil :inherit 'fixed-pitch))
  (display-fill-column-indicator-mode -1)
  (whitespace-mode -1))

(add-hook 'org-mode-hook #'gp/org-visual-setup)

(defun gp/toggle-code-line-length-highlighting ()
  "Toggle red highlighting for characters beyond column 80."
  (interactive)
  (if (bound-and-true-p whitespace-mode)
      (progn
        (whitespace-mode -1)
        (when (bound-and-true-p display-fill-column-indicator-mode)
          (display-fill-column-indicator-mode -1))
        (message "80-column overflow highlighting disabled"))
    (gp/code-visual-line-length-mode)
    (message "80-column overflow highlighting enabled")))

(global-set-key (kbd "C-c v 8") #'gp/toggle-code-line-length-highlighting)

(message "Loaded visual profile configuration")
