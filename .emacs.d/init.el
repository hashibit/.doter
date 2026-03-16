;; -*- lexical-binding: t -*-
;;; init.el --- Emacs Configuration

;; load emacs 24's package system. Add MELPA repository.
(define-key special-event-map [config-changed-event] #'ignore)

;;; ===================================================================
;;; CORE SYSTEM SETUP
;;; ===================================================================

;;; Package Management
(require 'package)
(setq package-archives
  '(("gnu" . "https://elpa.gnu.org/packages/")
     ("nongnu" . "https://elpa.nongnu.org/nongnu/")
     ("melpa" . "https://melpa.org/packages/")
     ))

;; 完全禁止自动包管理
(setq package-enable-at-startup nil
  package-check-signature nil
  ;; 禁止自动安装选中的包
  package-install-upgrade-built-in nil)

;; 禁用 package-selected-packages 的自动安装机制
(defun package--save-selected-packages (&rest _args)
  "Do nothing to prevent automatic package installation."
  nil)

;; 阻止启动时自动刷新包列表
(defvar my-startup-finished nil)
(defun my-block-package-refresh (orig-fun &rest args)
  "Block package-refresh-contents during startup."
  (when my-startup-finished
    (apply orig-fun args)))

(advice-add 'package-refresh-contents :around #'my-block-package-refresh)

;; 启动完成后恢复正常行为
(add-hook 'emacs-startup-hook
  (lambda ()
    (setq my-startup-finished t)))

(package-initialize)

;;; Performance Optimization
;; Minimize garbage collection during startup
(setq gc-cons-threshold most-positive-fixnum
  gc-cons-percentage 0.6)

;; Lower threshold back to 16 MiB after startup (default is 800kB)
(add-hook 'emacs-startup-hook
  (lambda ()
    (setq gc-cons-threshold (* 16 1024 1024)
      gc-cons-percentage 0.1)))

;;; Path Configuration
(add-to-list 'exec-path "/usr/local/bin/")
(add-to-list 'exec-path "/usr/bin/")
(add-to-list 'exec-path "/opt/homebrew/bin")

(setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))
(setenv "PATH" (concat "/usr/bin:" (getenv "PATH")))
(setenv "PATH" (concat "/opt/homebrew/bin:" (getenv "PATH")))
(setenv "PATH" (concat (expand-file-name "~/.local/bin:") (getenv "PATH")))

(setq mac-command-modifier 'super)


;;; Directory Setup
;; create the autosave dir if necessary, since emacs won't.
(make-directory "~/.emacs.d/.local/auto-save-list/" t)
(make-directory "~/.emacs.d/.local/autosaves/" t)
(make-directory "~/.emacs.d/.local/backups" t)

;;; Load Path Configuration
(add-to-list 'load-path (expand-file-name "~/.emacs.d/emacswiki.org"))
(add-to-list 'load-path (expand-file-name "~/.emacs.d/lisp"))
(add-to-list 'load-path (expand-file-name "~/.emacs.d/lisp/emacs-translate"))
(add-to-list 'load-path (expand-file-name "~/.emacs.d/lisp/initializers"))
(add-to-list 'custom-theme-load-path (expand-file-name "~/.emacs.d/lisp"))

;;; Core Libraries
(require 'cl-lib)  ; Updated from deprecated 'cl
(require 's)
(require 'bind-key) ; more powerful than global-set-key! seems have the highest priority

;;; Utility Libraries (no dependencies, loaded first)
(require 'custom-util-funcs)
(require 'my-utils)
(require 'init-eshell)

;;; ===================================================================
;;; BASIC SETTINGS & MODES
;;; ===================================================================

;;; Basic Settings
(setq warning-minimum-level :emergency
  visible-bell t
  ring-bell-function #'ignore
  custom-safe-themes t
  recenter-redisplay nil
  blink-cursor-blinks 0
  blink-cursor-interval 0.3)

(set-default 'truncate-lines t)

;; lsp-mode session file
(setq lsp-session-file (expand-file-name "~/.emacs.d/.local/.lsp-session-v1"))
(setq smex-save-file (expand-file-name "~/.emacs.d/.local/smex-items.cache"))

;; compile log with colors
(add-hook 'compilation-finish-functions 'bury-compile-buffer-if-successful)

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


(setq default-font-family "IBM Plex Mono")

(setq default-frame-alist
  `((vertical-scroll-bars . nil) ;隐藏滚动条
     (left-fringe . 0) ;关闭左fringe
     (right-fringe . 0) ;关闭右fringe
     (fullscreen . maximized)
     ))

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
(tool-bar-mode -1)
(menu-bar-mode -1)
(smerge-mode -1)
(tab-bar-mode 1)

(defun my-tab-name-formatter (tab index)
  (let* ((current (eq (car tab) 'current-tab))
          (buffer (and current (window-buffer)))
          (name (if buffer (buffer-name buffer) (alist-get 'name tab)))
          (modified (and buffer (buffer-modified-p buffer))))
    (propertize
      (format " %s %s " name (if modified "*" ""))
      'face (funcall tab-bar-tab-face-function tab))))

(setq tab-bar-tab-name-format-function 'my-tab-name-formatter)
(setq tab-bar-auto-width-max '((440) 40))   ;; default is ((220) 20), a little bit wider
(setq tab-bar-separator "")

;; New Tab
(setq tab-bar-new-tab-choice
  (lambda () (generate-new-buffer "untitled")))

;;; Frame and Border Configuration
(setq-default left-margin-width 0
  right-margin-width 0)
(setq frame-resize-pixelwise t)

(setq my-posframe-border-width (if (display-graphic-p) 1 0)
  my-posframe-fringe-width (if (display-graphic-p) 8 0))

;; Set symbol for the border
(set-display-table-slot standard-display-table 'vertical-border (make-glyph-code ?│))
;; truncate-lines right margin sign
(set-display-table-slot standard-display-table 0 ?→)

(setq-default cursor-in-non-selected-windows nil)

(defun my-change-window-divider ()
  (let ((display-table (or buffer-display-table standard-display-table)))
    (set-display-table-slot display-table 5 ?│)
    (set-window-display-table (selected-window) display-table)))
(add-hook 'window-configuration-change-hook 'my-change-window-divider)

;;; Theme Configuration
(setq window-divider-color "#06C668")

;; 水平 window 分隔线
(setq window-divider-default-places 'bottom-only)
(setq window-divider-default-bottom-width 1)
(setq window-divider-default-right-width 1)
;; 跟 mode-line 一样的颜色
(window-divider-mode 1)

(setq use-dark-theme-mode t)
(if use-dark-theme-mode
  (setq darker-window-bg-color "#181818"
    darker-window-fg-color "white"
    highlight-font-chars-face-fg "green"
    highlight-font-chars-face-underline t
    whitespace-tab-fg-color "#627D9D"
    whitespace-trailing-fg-color "#161c23"
    hl-line-bg-color "#1b2129")
  (setq darker-window-bg-color "#FFFFFF"
    darker-window-fg-color "black"
    highlight-font-chars-face-fg 'unspecified
    highlight-font-chars-face-underline t
    whitespace-tab-fg-color "#627D9D"
    whitespace-trailing-fg-color "#161c23"
    hl-line-bg-color (face-background 'highlight)))

(defun my-set-small-line-height ()
  (interactive)
  (setq-local default-text-properties '(line-spacing 0 line-height 1)))

(defun my-set-large-line-height ()
  (interactive)
  (setq-local default-text-properties '(line-spacing 0.11 line-height 1.11)))

(add-hook 'text-mode-hook #'my-set-large-line-height)
(add-hook 'prog-mode-hook #'my-set-large-line-height)
(add-hook 'conf-mode-hook #'my-set-large-line-height)
(add-hook 'org-mode-hook  #'my-set-large-line-height)

;; set global proxy
(my-set-proxy)

;;; Custom Faces
(defface my-highlight-font-chars-face
  `((t (:foreground ,highlight-font-chars-face-fg
         :underline (:color ,highlight-font-chars-face-fg :position t)
         :weight normal)))
  "custom highlight for treemacs current line")

(defface my-highlight-font-words-face
  `((t (:background "forest green"
         :foreground "cornsilk"
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

(toggle-truncate-lines nil)
(toggle-continuation-fringe-indicator)

;;; ===================================================================
;;; CORE MODULES & LIBRARIES
;;; ===================================================================

;;; Local Libraries (immediate loading required)
(require 'init-dired-plus)


;; Call functions from my-utils after loading

;;; Benchmark
(require 'init-benchmark)

;;; Core Initializers (immediate loading required)
(require 'init-god)
(require 'init-projectile)
(require 'init-treesit)
(require 'init-slime)
(require 'my-key-bindings)

(when (my-system-type-is-gnu)
  (require 'init-wayland))

(global-unset-key [(control z)])

;;; ===================================================================
;;; EDITING & TEXT MANIPULATION
;;; ===================================================================



(require 'cnfonts)
;; 让 cnfonts 在 Emacs 启动时自动生效。
(cnfonts-mode 1)
;; 添加两个字号增大缩小的快捷键
;; (define-key cnfonts-mode-map (kbd "C--") #'cnfonts-decrease-fontsize)
;; (define-key cnfonts-mode-map (kbd "C-=") #'cnfonts-increase-fontsize)
(setq cnfonts-use-system-type t)
(setq cnfonts-personal-fontnames '(("IBM Plex Mono") ("IBM Plex Sans SC" "PingFang SC" "等距更纱黑体 SC")))

;; Emoji 字体调小一点
(when (member "Apple Color Emoji" (font-family-list))
  (set-fontset-font "fontset-default"
    'unicode
    (font-spec :family "Apple Color Emoji" :size 12)
    nil 'append))



;;; Basic Editing Enhancements
(delete-selection-mode 1)
(column-number-mode 1)
(global-auto-revert-mode 1)
(superword-mode 1)  ; treats underscores as part of words

;;; Text and Programming Modes
(require 'init-whitespace-mode)
(require 'init-iedit)
(require 'init-expand-region)
(toggle-truncate-lines t)

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
(require 'init-neotree)
(require 'init-treemacs)
(require 'init-multi-cursor)
(require 'init-undo-tree)
(require 'init-hydra)
(require 'init-deadgrep)
(require 'init-dired-ibuffer)

;;; ===================================================================
;;; DEVELOPMENT TOOLS & IDE FEATURES
;;; ===================================================================

(semantic-idle-scheduler-mode -1)
(global-semantic-idle-scheduler-mode -1)

;;; Code Intelligence and LSP
(require 'init-eldoc)
(require 'init-eglot)
(require 'init-company)
(require 'init-yasnippet)
(require 'init-flymake)

;;; Code Intelligence Toggle
(require 'my-toggle-code-intelligence)
(add-hook 'isearch-mode-hook #'my-disable-code-intelligence)
(add-hook 'isearch-mode-end-hook #'my-enable-code-intelligence)

(defun my-change-cursor-type-when-isearch ()
  (interactive)
  (if (bound-and-true-p isearch-mode)
    (progn
      (setq cursor-type 'bar)
      (set-cursor-color "yellow"))
    (progn
      (setq cursor-type 'box)
      (set-cursor-color "red"))))
(add-hook 'isearch-mode-hook #'my-change-cursor-type-when-isearch)
(add-hook 'isearch-mode-end-hook #'my-change-cursor-type-when-isearch)

;; Safe isearch 全局高亮
(require 'my-isearch-highlight-all)
(add-hook 'isearch-update-post-hook #'my-isearch-highlight-all-matches)
(add-hook 'isearch-mode-end-hook #'my-isearch-cleanup)

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
(require 'init-vterm)

;;; Special Mode Tools
(require 'init-markdown)
(require 'init-ace-window)
(require 'init-blamer)
(require 'init-diminish)
(require 'init-dashboard)
;;; (require 'init-autopep8)
(require 'init-imenu)
(require 'init-modeline)

(use-package xwidget
  :ensure nil
  :bind (("C-c w s" . my/xwidget-webkit-search))
  :bind (:map xwidget-webkit-mode-map
          ("r" . xwidget-webkit-reload)
          ("L" . xwidget-webkit-back)
          ("H" . xwidget-webkit-forward)
          ("j" . xwidget-webkit-scroll-up-line)
          ("k" . xwidget-webkit-scroll-down-line)
          ("+" . xwidget-webkit-zoom-in)
          ("-" . xwidget-webkit-zoom-out)
          ;; 添加复制粘贴绑定
          ("s-c" . xwidget-webkit-copy-selection-as-kill)
          ("s-v" . xwidget-webkit-paste)
          ("s-a" . xwidget-webkit-select-all)          ; Cmd+A 全选
          ("s-r" . xwidget-webkit-reload)              ; Cmd+R 刷新
          ("s-l" . xwidget-webkit-current-url)
          )
  :config
  (defun my/xwidget-webkit-search ()
    "搜索功能"
    (interactive)
    (let ((query (read-string "Search: ")))
      (xwidget-webkit-browse-url (concat "https://www.google.com/search?q="
                                   (url-hexify-string query))))))

(use-package xwwp
  :ensure t
  :config
  (require 'xwwp)
  :bind (("C-c w o" . xwwp))
  :custom
  (xwwp-follow-link-completion-system 'ivy)
  :bind (:map xwidget-webkit-mode-map
          ("v" . xwwp-follow-link)))

(use-package hl-todo
  :ensure t
  :config
  (global-hl-todo-mode 1)
  )



(require 'init-claude-code)

;; (require 'claude-posframe)
(require 'gitignore-generator)



(use-package indent-bars
  :custom
  (indent-bars-no-descend-lists t) ; no extra bars in continued func arg lists
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  ;; Minimal colorpop:
  (indent-bars-color '(highlight :face-bg t :blend 0.5))
  (indent-bars-pattern ".")
  (indent-bars-width-frac 0.1)
  (indent-bars-pad-frac 0.1)
  (indent-bars-zigzag nil)
  (indent-bars-color-by-depth '(:regexp "outline-\\([0-9]+\\)" :blend 1) ); blend=1: blend with BG only
  (indent-bars-highlight-current-depth '(:blend 0.5)) ; pump up the BG blend on current
  (indent-bars-display-on-blank-lines t)
  :hook
  (prog-mode . indent-bars-mode)
  )

(use-package systemd
  :ensure t
  :defer t
  )


;;; Text Mode Enhancements
(add-hook 'org-mode-hook #'valign-mode)
(add-hook 'markdown-mode-hook #'valign-mode)

;;; ===================================================================
;;; KEY BINDINGS & COMMANDS
;;; ===================================================================

;;; Custom Key Functions
(defun my-escape-key ()
  (interactive)
  (refresh-current-mode)
  (when isearch-mode (isearch-abort) (isearch-abort))  ;; must double abort
  (when (my-god-this-is-normal-editor-buffer (buffer-name))
    (when (bound-and-true-p multiple-cursors-mode) (multiple-cursors-mode 0))
    (when (bound-and-true-p iedit-mode) (iedit-done)) ;; exit iedit mode, if needed.
    (ignore-errors (company-cancel))
    (ignore-errors (remove-all-highlight)))
  (ignore-errors (flymake-start)) ;; but show errors
  (keyboard-quit)
  (keyboard-quit-context+)) ;; from custom-util-funcs.el

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
(add-hook 'view-mode-hook 'View-exit)

;; Diactive my all special keys for minibuffer
(add-hook 'minibuffer-setup-hook #'(lambda () (my-keys-minor-mode 0)))
(add-hook 'minibuffer-setup-hook #'(lambda () (my-special-buffer-keys-minor-mode 0)))

(require 'init-selected)
(put 'scroll-left 'disabled nil)

;;; ===================================================================
;;; CUSTOM VARIABLES & FACES
;;; ===================================================================

;;; Custom Faces Configuration
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
  '(avy-lead-face ((t (:background "#161c23" :weight normal :foreground "deeppink"))))
  '(avy-lead-face-0 ((t (:background "#161c23" :foreground "#FFB400"))))
  '(aw-mode-line-face ((t (:inherit nil))))
  '(cfrs-border-color ((t (:background "yellow"))))
  '(company-tooltip ((t (:background "black"))))
  '(company-tooltip-common ((t (:weight normal :foreground "#7FDC59"))))
  '(company-tooltip-selection ((t (:weight normal))))
  '(deadgrep-match-face ((t (:inherit lazy-highlight))))
  '(eglot-diagnostic-tag-deprecated-face ((t (:underline nil :strike-through nil :foreground "yellow"))))
  '(eglot-diagnostic-tag-unnecessary-face ((t (:foreground "gray" :underline nil))))
  '(eglot-mode-line ((t (:inherit nil :weight bold))))
  '(eldoc-box-border ((t (:background "#569CD6"))))
  '(flymake-error ((t (:foreground "Yellow" :background "black" :underline nil :weight normal))))
  '(flymake-note ((t (:underline nil))))
  '(flymake-warning ((t (:underline nil))))
  '(font-lock-doc-face ((t (:inherit font-lock-comment-face :foreground "gray"))))
  '(font-lock-keyword-face ((t (:foreground "orchid" :weight normal))))
  '(font-lock-preprocessor-face ((t (:weight normal))))
  '(fringe ((t (:foreground unspecified :background unspecified :inherit default))))
  '(highlight-indent-guides-character-face ((t (:inherit font-lock-doc-markup-face))))
  '(iedit-occurrence ((t (:foreground "black" :background "yellow"))))
  '(isearch ((t (:foreground "white" :background "deeppink" :weight normal))))
  '(ivy-minibuffer-match-face-1 ((t (:weight regular))))
  '(ivy-minibuffer-match-face-2 ((t (:weight regular))))
  '(ivy-minibuffer-match-face-3 ((t (:weight regular))))
  '(ivy-minibuffer-match-face-4 ((t (:weight regular))))
  '(lazy-highlight ((t (:background "#7FDC59" :foreground "#161c23" :weight normal))))
  '(line-number ((t (:inherit default :foreground "gray33" :slant normal :weight normal))))
  '(line-number-current-line ((t (:background "#1b2129" :foreground "white" :slant normal :weight normal))))
  '(mode-line ((t (:background "#415367" :foreground "#e5ded6" :underline (:color foreground-color :style line :position t)))))
  '(mode-line-active ((t (:background "#1a202c" :foreground "green" :box nil :underline nil))))
  '(mode-line-highlight ((t (:box nil :foreground "green"))))
  '(mode-line-inactive ((t (:background "#1a202c" :foreground "#a0aec0" :box nil :underline nil))))
  '(region ((t (:background "#214283" :distant-foreground "#707080"))))
  '(rg-context-face ((t (:inherit nil :foreground "#C6B8AD"))))
  '(rg-match-face ((t (:inherit lazy-highlight))))
  '(ripgrep-match-face ((t (:inherit my-highlight-font-words-face))))
  '(shadow ((t (:foreground "#569CD6"))))
  '(show-paren-match ((t (:foreground "green" :background "#11501B" :weight normal :underline (:position t)))))
  '(sideline-flymake-error ((t (:inherit nil :background "red" :foreground "white"))))
  '(sideline-flymake-note ((t (:inherit nil :background "lightblue" :foreground "black"))))
  '(sideline-flymake-warning ((t (:inherit nil :background "lightyellow" :foreground "black"))))
  '(success ((t (:foreground "Green1" :weight regular))))
  '(symbol-overlay-default-face ((t (:inherit my-highlight-font-words-face))))
  '(tab-bar ((t (:background "#1e1e1e"))))
  '(tab-bar-tab ((t (:foreground "black" :background "yellow" :box (:line-width 2 :color "yellow" :style flat-button)))))
  '(tooltip ((t (:font "IBM Plex Mono-14.0" :box nil))))
  '(treemacs-directory-collapsed-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#57D8D4"))))
  '(treemacs-directory-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#57D8D4"))))
  '(treemacs-file-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-added-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-conflict-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-ignored-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-modified-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#D0BF68"))))
  '(treemacs-git-renamed-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-unmodified-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-untracked-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-root-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#57D8D4"))))
  '(treemacs-tags-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(vertical-border ((t (:inherit shadow :foreground "#569CD6"))))
  '(whitespace-tab ((t (:foreground unspecified :background unspecified :inherit shadow))))
  '(whitespace-trailing ((t (:foreground unspecified :background unspecified :inherit shadow))))
  '(widget-field ((t (:background "#C6B8AD" :foreground "black"))))
  '(window-divider ((t (:inherit shadow))))
  '(window-divider-first-pixel ((t (:inherit shadow))))
  '(window-divider-last-pixel ((t (:inherit shadow))))
  '(yas-field-highlight-face ((t (:inherit my-highlight-font-words-face)))))

;;; Custom Variables
(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
  '(auto-save-file-name-transforms '((".*" "~/.emacs.d/.local/autosaves/\\1" t)))
  '(auto-save-list-file-prefix (expand-file-name "~/.emacs.d/.local/auto-save-list/"))
  '(backup-directory-alist '((".*" . "~/.emacs.d/.local/backups/")))
  '(create-lockfiles nil)
  '(helm-minibuffer-history-key "M-p")
  '(inhibit-startup-screen t)
  '(leetcode-prefer-language "cpp")
  '(leetcode-save-solutions t)
  '(package-selected-packages
     '(jtsx sideline-eglot sideline-flymake sideline
        highlight-indent-guides treemacs-nerd-icons treemacs python-ts
        poetry dockerfile-mode popper spacious-padding afternoon-theme
        ansible apheleia atom-one-dark-theme auto-dim-other-buffers
        bazel beacon benchmark-init blamer centaur-tabs
        challenger-deep-theme color-theme-sanityinc-tomorrow
        company-posframe company-prescient company-qml corfu-terminal
        counsel csv-mode cyberpunk-theme dashboard dashboard-hackernews
        diminish disable-mouse easy-kill eglot elisp-autofmt elisp-def
        elisp-refs elisp-slime-nav eterm-256color format-all general
        google-c-style helm-rg highlight-numbers highlight-parentheses
        imenu-list impatient-mode inkpot-theme ivy ivy-posframe
        ivy-xref jdecomp jsonrpc key-chord known leetcode lispy
        lsp-python-ms markdown-mode markdown-toc markdownfmt
        modus-themes moe-theme mwim nano-theme neotree nimbus-theme
        package-lint paredit phi-search popon popup-switcher popwin
        prescient project projectsile-mode protobuf-mode py-autopep8
        qml-mode rainbow-delimiters reformatter ripgrep rjsx-mode
        selected slime slime-company smart-jump smart-mode-line
        smooth-scrolling solaire-mode srcery-theme srefactor swift-mode
        switch-buffer-functions symbol-overlay treemacs-all-the-icons
        treesit-auto typescript-mode undo-tree valign vs-dark-theme
        vscode-dark-plus-theme vterm vue-mode with-proxy
        with-simulated-input xclip yasnippet))
  '(package-vc-selected-packages
     '((claude-code :url "https://github.com/stevemolitor/claude-code.el")))
  '(pos-tip-background-color "#1d1d2b")
  '(pos-tip-foreground-color "#d4d4d6")
  '(recentf-save-file (expand-file-name "~/.emacs.d/.local/recentf"))
  '(safe-local-variable-values
     '((eval setq-local cider-preferred-build-tool 'clojure-cli
         cider-default-cljs-repl 'shadow)
        (projectile-project-root
          . "/Users/jiechen/work/code/clj/ringbell")
        (python-shell-interpreter-args . "run python")
        (projectile-project-root . ".")
        (python-shell-interpreter-args . "python -i")
        (python-shell-interpreter . "uv")
        (eglot-server-programs
          (python-mode "basedpyright-langserver" "--stdio"))))
  '(warning-suppress-log-types '((emacs) (use-package) (lsp-mode)))
  '(warning-suppress-types '((use-package) (lsp-mode))))






;;; init.el ends here
