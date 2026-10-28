;;; init.el --- Emacs Configuration -*- lexical-binding: t -*-

;; Ignore macOS system-appearance change events.
(keymap-set special-event-map "<config-changed-event>" #'ignore)

;;; ===================================================================
;;; CORE SYSTEM SETUP
;;; ===================================================================

;;; Package Management
(require 'package)
(setopt package-archives
  '(("gnu" . "https://elpa.gnu.org/packages/")
     ("nongnu" . "https://elpa.nongnu.org/nongnu/")
     ("melpa" . "https://melpa.org/packages/")
     ))

;; 完全禁止自动包管理 (package-enable-at-startup is set in early-init.el)
(setopt package-check-signature nil
  ;; Read one combined autoload file at startup.
  ;; package.el refreshes it after each install or delete.
  package-quickstart t
  ;; 禁止自动安装选中的包
  package-install-upgrade-built-in nil)

;; 禁用 package-selected-packages 的自动安装机制
(advice-add 'package--save-selected-packages :override #'ignore)

;; 阻止启动时自动刷新包列表，启动完成（after-init-time 已设置）后恢复正常行为
(defun my-block-package-refresh (orig-fun &rest args)
  "Block package-refresh-contents during startup."
  (when after-init-time
    (apply orig-fun args)))

(advice-add 'package-refresh-contents :around #'my-block-package-refresh)

(package-initialize)

;;; Performance Optimization
;; GC is deferred in early-init.el; lower threshold back to 16 MiB after
;; startup (default is 800kB).
(defun my-restore-gc-threshold ()
  (setq gc-cons-threshold (* 16 1024 1024)
    gc-cons-percentage 0.1))
(add-hook 'emacs-startup-hook #'my-restore-gc-threshold)

;;; Path Configuration
;; PATH and exec-path come from the login shell via exec-path-from-shell
;; (see init-exec-path.el).

(setopt mac-command-modifier 'super)


;;; Directory Setup
(defconst my-local-dir (locate-user-emacs-file ".local/")
  "Directory for state, caches, backups and other generated files.")

;; create the autosave/backup dirs if necessary, since emacs won't.
(dolist (dir '("auto-save-list" "autosaves" "backups"))
  (make-directory (expand-file-name dir my-local-dir) t))

(setopt backup-directory-alist `((".*" . ,(expand-file-name "backups/" my-local-dir)))
  auto-save-file-name-transforms `((".*" ,(expand-file-name "autosaves/" my-local-dir) t))
  auto-save-list-file-prefix (expand-file-name "auto-save-list/" my-local-dir)
  recentf-save-file (expand-file-name "recentf" my-local-dir)
  create-lockfiles nil
  inhibit-startup-screen t
  ;; Plain *scratch*. lisp-interaction-mode would run the elisp hooks at
  ;; startup: lispy loads all of Org (about 0.9s). M-x lisp-interaction-mode
  ;; turns it on when needed.
  initial-major-mode 'fundamental-mode)

;; Customize writes go here instead of init.el.
(setopt custom-file (locate-user-emacs-file "custom-settings.el"))

;;; Load Path Configuration
(dolist (dir '("emacswiki.org" "lisp" "lisp/emacs-translate" "lisp/initializers"))
  (add-to-list 'load-path (locate-user-emacs-file dir)))
(add-to-list 'custom-theme-load-path (locate-user-emacs-file "lisp"))

;;; Core Libraries
(require 'cl-lib)  ; Updated from deprecated 'cl
(require 's)
(require 'bind-key) ; more powerful than global-set-key! seems have the highest priority

;;; Utility Libraries (no dependencies, loaded first)
(require 'custom-util-funcs)
(require 'my-utils)
(require 'init-exec-path)
(require 'init-eshell)

;;; ===================================================================
;;; BASIC SETTINGS & MODES
;;; ===================================================================

;;; Basic Settings
(setopt warning-minimum-level :emergency
  visible-bell t
  ring-bell-function #'ignore
  custom-safe-themes t
  recenter-redisplay nil
  blink-cursor-blinks 0
  blink-cursor-interval 0.3)

(setq-default truncate-lines t)

;; lsp-mode session file
(setq lsp-session-file (expand-file-name ".lsp-session-v1" my-local-dir))
(setq smex-save-file (expand-file-name "smex-items.cache" my-local-dir))

;; compile log with colors
(add-hook 'compilation-finish-functions #'bury-compile-buffer-if-successful)

;;; Terminal-specific Configuration
(unless (display-graphic-p)
  (require 'my-catch-term-escape-key)
  (require 'init-term-cursor)
  (require 'my-term-popup)
  (xclip-mode 1)
  )

;;; ===================================================================
;;; UI & VISUAL CONFIGURATION
;;; ===================================================================


(defvar default-font-family "IBM Plex Mono")

;; Frame parameters (scroll bars, fringes, maximized) live in early-init.el.

(defun center-frame ()
  "Center the frame on the screen."
  (interactive)
  ;; 获取显示器的尺寸
  (let* ((screen-width (x-display-pixel-width))
          (screen-height (x-display-pixel-height))
          ;; 获取当前框架的尺寸
          (frame-width (frame-pixel-width))
          (frame-height (frame-pixel-height))
          ;; 计算新的框架位置
          (left (/ (- screen-width frame-width) 2))
          (top (/ (- screen-height frame-height) 2)))
    ;; 设置框架的位置
    (set-frame-position (selected-frame) left top)))

;; ;; 在图形界面模式下应用此功能
;; (when (display-graphic-p)
;;   ;; 在窗口设置完成后调用
;;   (add-hook 'window-setup-hook 'center-frame t))

;;; UI Mode Configuration
;; early-init.el already hides the tool bar (tool-bar-lines 0).
;; Calling (tool-bar-mode -1) here redraws the frame: about 0.1s.
;; (tool-bar-mode -1)
(setq tool-bar-mode nil)
(menu-bar-mode -1)
(tab-bar-mode 1)

(require 'server)
(unless (server-running-p)
  (server-start))

(defvar my-tab-bar-ignored-buffer-regexps
  '("^ \\*Treemacs" "^ \\*Minibuf" "^ \\*Pos-Frame"
     "^\\*NeoTree" "^\\*Woof" "^\\*Popper"
     "^\\*compilation" "^\\*Help" "^\\*Apropos" "^\\*eldoc"
     "^\\*Messages" "^\\*Embark" "^\\*which-key"
     "^\\*Backtrace" "^\\*Warnings" "^\\*Ibuffer"
     "^\\*claude")
  "Buffer name regexps that should not be used as tab names.")

(defvar my-tab-last-good-name (make-hash-table :test 'equal))

(defun my-tab-name-formatter (tab index)
  (let* ((current (eq (car tab) 'current-tab))
          (buffer (and current (window-buffer)))
          (explicit-name (alist-get 'explicit-name tab))
          (stored-name (alist-get 'name tab))
          (buf-name (and buffer (buffer-name buffer)))
          (ignored-p (and buf-name
                       (cl-some (lambda (re) (string-match-p re buf-name))
                         my-tab-bar-ignored-buffer-regexps)))
          (name
            (cond
              (explicit-name stored-name)
              ((not buffer) stored-name)
              (ignored-p
                (or (gethash index my-tab-last-good-name) stored-name))
              (t
                (puthash index buf-name my-tab-last-good-name)
                buf-name)))
          (modified (and buffer (not ignored-p) (buffer-modified-p buffer))))
    (propertize
      (format " %d:%s %s " index name (if modified "*" ""))
      'face (funcall tab-bar-tab-face-function tab))))

(setopt tab-bar-tab-name-format-function #'my-tab-name-formatter)
(setopt tab-bar-auto-width-max '((330) 40))   ;; default is ((220) 20), a little bit wider
(setopt tab-bar-separator "")

;; New Tab
(defun my-tab-bar-new-untitled-buffer ()
  (generate-new-buffer "untitled"))
(setopt tab-bar-new-tab-choice #'my-tab-bar-new-untitled-buffer)

;;; Frame and Border Configuration
(setq-default left-margin-width 0
  right-margin-width 0)
(setopt frame-resize-pixelwise t)

(defvar my-posframe-border-width (if (display-graphic-p) 1 0))
(defvar my-posframe-fringe-width (if (display-graphic-p) 8 0))

;; Set symbol for the border
(set-display-table-slot standard-display-table 'vertical-border (make-glyph-code ?│))
;; truncate-lines right margin sign
(set-display-table-slot standard-display-table 'truncation ?→)

(setq-default cursor-in-non-selected-windows nil)

;; 不再挂到 window-configuration-change-hook：上面 standard-display-table 的
;; vertical-border 已经全局生效。
(defun my-change-window-divider ()
  (let ((display-table (or buffer-display-table standard-display-table)))
    (set-display-table-slot display-table 'vertical-border ?│)
    (set-window-display-table (selected-window) display-table)))

;;; Theme Configuration
(defvar window-divider-color "#06C668")

;; 水平 window 分隔线
(setopt window-divider-default-places 'bottom-only)
(setopt window-divider-default-bottom-width 1)
(setopt window-divider-default-right-width 1)
;; 跟 mode-line 一样的颜色
(window-divider-mode 1)

(defvar use-dark-theme-mode t)
(defvar darker-window-bg-color (if use-dark-theme-mode "#181818" "#FFFFFF"))
(defvar darker-window-fg-color (if use-dark-theme-mode "white" "black"))
(defvar highlight-font-chars-face-fg (if use-dark-theme-mode "green" 'unspecified))
(defvar highlight-font-chars-face-underline t)
(defvar whitespace-tab-fg-color "#627D9D")
(defvar whitespace-trailing-fg-color "#161c23")
(defvar hl-line-bg-color
  ;; dark: "#1b2129"
  (if use-dark-theme-mode nil (face-background 'highlight)))



;; use header-line to mimic buffer top padding
(defun my-set-header-line ()
  (interactive)
  (set-face-attribute 'header-line nil
    :background darker-window-bg-color
    :box nil
    :overline nil
    :height 10)
  (setq-local header-line-format " "))

(defun my-unset-header-line()
  (interactive)
  (setq-local header-line-format nil))

(add-hook 'prog-mode-hook #'my-set-header-line)


(add-hook 'prog-mode-hook #'hs-minor-mode)

;; (defun my-set-small-line-height ()
;;   (interactive)
;;   (setq-local default-text-properties '(line-spacing 0 line-height 1)))

;; (defun my-set-large-line-height ()
;;   (interactive)
;;   (setq-local default-text-properpties '(line-spacing 0.15 line-height 1.15)))

(defun my-set-small-line-height ()
  (interactive)
  (setq-local line-spacing 0))

(defun my-set-large-line-height ()
  (interactive)
  (setq-local line-spacing 0.15))

(add-hook 'text-mode-hook #'my-set-large-line-height)
(add-hook 'prog-mode-hook #'my-set-large-line-height)
(add-hook 'conf-mode-hook #'my-set-large-line-height)
(add-hook 'org-mode-hook  #'my-set-large-line-height)

;; set global proxy
;; (my-set-proxy)

;;; Custom Faces
(defface my-highlight-font-chars-face
  `((t (:foreground ,highlight-font-chars-face-fg
         :underline (:color ,highlight-font-chars-face-fg :position t)
         :weight normal)))
  "custom highlight for treemacs current line")



; (defface my-highlight-font-words-face
;   `((t (:background "forest green"
;          :foreground "cornsilk"
;          :underline nil
;          :weight normal)))
;   "custom highlight for treemacs current line")

(defface my-highlight-font-words-face
  `((t (:background "#1e3a5f"
         :foreground "#c8d8ff"
         :underline nil
         :weight normal)))
  "custom highlight for treemacs current line")



;;  ;;; Theme Loading and Face Configuration
;;  (use-package vscode-dark-plus-theme
;;    :ensure t
;;    :config
;;    ;; 禁用有问题的 org-todo box 配置
;;    (setq vscode-dark-plus-box-org-todo nil)
;;    (load-theme 'vscode-dark-plus t)
;;    (add-hook 'after-load-theme-hook
;;      (lambda ()
;;        (set-face-attribute 'font-lock-keyword-face nil :foreground "orchid")))
;;    )

;; (load-theme 'doom-material-dark t)
(defun my-unset-region-foreground (&rest _)
  (set-face-attribute 'region nil :foreground 'unspecified))
(add-hook 'enable-theme-functions #'my-unset-region-foreground)
(load-theme 'kaolin-galaxy t)

;;; Terminal Colors
(require 'ansi-color)
(setq ansi-color-names-vector ["black" "tomato" "PaleGreen2" "gold1" "DeepSkyBlue1" "MediumOrchid1" "cyan" "white"])
(setq ansi-color-map (ansi-color-make-color-map))

;;; Line Numbers and Visual Enhancements
;; for hl-line+.el
(setq hl-line-inhibit-highlighting-for-modes
  '(dired-mode deadgrep-mode deadgrep-edit-mode treemacs-mode))

(global-hl-line-mode 0)

;;; ===================================================================
;;; CORE MODULES & LIBRARIES
;;; ===================================================================

;;; Local Libraries (immediate loading required)
(require 'init-dired-plus)


;; Call functions from my-utils after loading

;;; Benchmark
;; (require 'init-benchmark)

;;; Core Initializers (immediate loading required)
(require 'init-god)
(require 'init-projectile)
(require 'init-treesit)
(require 'init-slime)
(require 'init-eww)
(require 'my-key-bindings)
(require 'my-super-keys)

(when (my-system-type-is-gnu)
  (require 'init-wayland))

(keymap-global-unset "C-z")

;;; ===================================================================
;;; EDITING & TEXT MANIPULATION
;;; ===================================================================



(require 'init-cnfonts)



;;; Basic Editing Enhancements
(delete-selection-mode 1)
(column-number-mode 1)
(global-auto-revert-mode 1)
(superword-mode 1)  ; treats underscores as part of words

(defun my-switch-to-prev-buffer-skip-p (window buffer _bury-or-kill)
  (or
    ;; 跳过 * 开头的 internal buffer
    (string-match-p "\\`\\*" (buffer-name buffer))
    ;; 跳过非当前 project 的 buffer
    (let ((current-root
            (buffer-local-value 'projectile-project-root (window-buffer window))))
      (and current-root
        (with-current-buffer buffer
          (not (equal projectile-project-root current-root)))))))
(setopt switch-to-prev-buffer-skip #'my-switch-to-prev-buffer-skip-p)

;;; Text and Programming Modes
(require 'init-whitespace-mode)
(require 'init-iedit)
(require 'init-expand-region)

;;; Smart Parentheses and Electric Mode
(require 'init-smartparens)
(require 'init-electric)

;;; Enhanced Editing Tools
(require 'init-mwim)
;; (require 'init-yank-indent)
(require 'init-srefactor)

;; .gitignore  .dockerignore .npmignore
(add-to-list 'auto-mode-alist '("\\.[^.]+ignore\\'" . conf-mode))
;; .env
(add-to-list 'auto-mode-alist '("\\.env.*\\'" . conf-mode))

;;; ===================================================================
;;; NAVIGATION & SEARCH
;;; ===================================================================

;;; Navigation and Jumping
(require 'init-nice-jumper)
(require 'init-mouse)
(require 'init-xref)
(require 'init-avy)
(require 'init-scroll-keys)

;;; Search Tools
(require 'init-ripgrep)

;;; Popup Windows
(require 'init-popper)

(require 'hidden-mode-line)

;;; ===================================================================
;;; VISUAL ENHANCEMENTS & THEMES
;;; ===================================================================

;;; Display and Visual Enhancements
(require 'init-display-line-numbers)
(require 'init-highlight-numbers)
;; (require 'init-highlight-indent-guides)
(require 'init-rainbow-delimiters)
(require 'my-highlight-current-line)
(require 'init-highlight)

;;; UI and Navigation Tools
(require 'init-all-the-icons)
;; treemacs replaces neotree.
;; (require 'init-neotree)
(require 'init-treemacs)
(require 'init-multi-cursor)
(require 'init-undo-tree)
(require 'init-hydra)
(require 'init-deadgrep)
(require 'init-dired-ibuffer)

;;; ===================================================================
;;; DEVELOPMENT TOOLS & IDE FEATURES
;;; ===================================================================

;;; Code Intelligence and LSP
(require 'init-eldoc)
(require 'init-eglot)
(require 'init-company)
(require 'init-yasnippet)
(require 'init-flymake)

;;; Code Intelligence Toggle
(require 'my-toggle-code-intelligence)
(require 'init-isearch)

;;; Additional Tools
;; (require 'init-tabby)
(require 'init-ivy)
(require 'init-format-all)

;;; ===================================================================
;;; PROGRAMMING LANGUAGES
;;; ===================================================================

;;; Language Support
(require 'init-lang-go)
(require 'init-cmake-project)
(require 'init-lang-cpp)
(require 'init-lang-python)
(require 'init-lang-zig)
(require 'init-lang-typescript)
(require 'init-lang-swift)
(require 'init-lang-rust)
(require 'init-lang-scala)
(require 'init-lang-yaml)
(require 'init-lang-qml)
(require 'init-lang-java)
(require 'init-lang-clojure)
(require 'init-ansible)

;;; Lisp Development
(require 'init-emacs-lispy)

;;; ===================================================================
;;; SPECIAL MODES & TOOLS
;;; ===================================================================

;;; Terminal Emulator
(require 'init-eat)
(require 'my-eat-popup)
(require 'eat-floating)
(require 'init-eat-claude)

;;; Special Mode Tools
(require 'init-markdown)
(require 'init-ace-window)
(require 'init-blamer)
(require 'init-diminish)
;; (require 'init-dashboard)
;;; (require 'init-autopep8)
(require 'init-imenu)
(require 'init-modeline)

(require 'init-xwidget)

(require 'init-hl-todo)



;; (require 'init-claude-code)

;; (require 'claude-posframe)
(require 'gitignore-generator)
(autoload 'emacs-translate-dwim "emacs-translate" nil t)



(require 'init-indent-bars)

(require 'init-systemd)


;; (use-package sis
;;   :ensure t
;;   :config
;;   (setq sis-english-source "com.apple.keylayout.ABC")
;;   (sis-ism-lazyman-config
;;     "com.apple.keylayout.ABC"
;;     "com.baidu.inputmethod.BaiduIM.pinyin"
;;     'macism)

;;   ;; 【关键】设置需要强制英文的前缀键
;;   (setq sis-prefix-override-keys '("C-x" "C-c" "C-w"))

;;   ;; ;; 开启自动化
;;   ;; (sis-global-respect-mode t)
;;   ;; (sis-global-context-mode t)
;;   ;; (sis-global-inline-mode t)

;;   ;; god-mode 状态切换时强制英文
;;   (add-hook 'god-mode-enabled-hook #'sis-set-english)
;;   (add-hook 'god-mode-disabled-hook #'sis-context))


;;; Text Mode Enhancements
(add-hook 'org-mode-hook #'valign-mode)
(add-hook 'markdown-mode-hook #'valign-mode)

;;; ===================================================================
;;; KEY BINDINGS & COMMANDS
;;; ===================================================================

;;; Custom Key Functions
(defun my-escape-key ()
  (interactive)
  (if (derived-mode-p 'eat-mode)
    (eat-self-input 1 ?\e)
    (my-init-god-mode-for-new-buffer)  ;; ESC always forces god-mode on
    (when isearch-mode (isearch-abort) (isearch-abort))  ;; must double abort
    (when (my-god-this-is-normal-editor-buffer (buffer-name))
      (when (bound-and-true-p multiple-cursors-mode) (multiple-cursors-mode 0))
      (when (bound-and-true-p iedit-mode) (iedit-done)) ;; exit iedit mode, if needed.
      (ignore-errors (company-cancel))
      (ignore-errors (remove-all-highlight)))
    (ignore-errors (flymake-start)) ;; but show errors
    (keyboard-quit)
    (keyboard-quit-context+))) ;; from custom-util-funcs.el

;;; Global Key Bindings
(bind-key (kbd "<escape>") #'my-escape-key)
(bind-key (kbd "<escape>") #'minibuffer-keyboard-quit minibuffer-local-map)

(bind-key (kbd "C-S-k") #'my-delete-to-beginning)
(bind-key (kbd "C-k") #'my-delete-to-end)
(bind-key (kbd "C-j") #'save-buffer)

(bind-key* (kbd "C-<wheel-up>") #'ignore)
(bind-key* (kbd "C-<wheel-down>") #'ignore)

(when (display-graphic-p)
  (bind-key [escape] 'my-escape-key)
  (define-key input-decode-map [?\C-\[] (kbd "<C-[>"))
  (bind-key (kbd "<C-[>") 'my-escape-key))

;;; ===================================================================
;;; FINAL SETUP & MINIBUFFER
;;; ===================================================================

;;; Final Setup
(which-key-mode 1)
(save-place-mode 1)

;;; View Mode and Minibuffer Setup
(add-hook 'view-mode-hook #'View-exit)

;; Diactive my all special keys for minibuffer
(defun my-disable-special-keys-in-minibuffer ()
  (my-keys-minor-mode 0)
  (my-special-buffer-keys-minor-mode 0))
(add-hook 'minibuffer-setup-hook #'my-disable-special-keys-in-minibuffer)

(require 'init-selected)
(put 'scroll-left 'disabled nil)

;;; ===================================================================
;;; CUSTOM VARIABLES & FACES
;;; ===================================================================

;; Faces and Customize-managed variables live in `custom-file'.
(load custom-file 'noerror 'nomessage)

;;; init.el ends here
