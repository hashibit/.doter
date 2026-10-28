;;; init-lang-clojure.el --- Clojure development configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Clojure 开发环境配置

;;; Code:

;; Package variables, declared for the byte compiler.
(defvar cider-auto-select-error-buffer)
(defvar cider-auto-select-test-report-buffer)
(defvar cider-save-file-on-load)
(defvar cider-font-lock-dynamically)
(defvar cider-test-show-report-on-success)
(defvar cider-repl-mode-map)
(defvar cider-repl-display-help-banner)
(defvar cider-repl-pop-to-buffer-on-connect)
(defvar cider-repl-use-pretty-printing)
(defvar cider-repl-result-prefix)
(defvar cider-repl-history-size)
(defvar cider-repl-history-file)
(defvar cider-mode-map)

;; =============================================================================
;; Clojure Mode (使用 treesit)
;; =============================================================================

(use-package clojure-ts-mode
  :ensure t
  :mode (("\\.clj\\'" . clojure-ts-mode)
         ("\\.cljs\\'" . clojure-ts-mode)
         ("\\.cljc\\'" . clojure-ts-mode)
         ("\\.edn\\'" . clojure-ts-mode))
  :custom
  ;; clojure-ts-mode 自己的缩进设置 (没有 align-arguments 对应项，用默认 semantic)
  (clojure-ts-align-forms-automatically t)
  (clojure-ts-semantic-indent-rules
   '(("defroutes" . ((:inner 0)))
     ("GET" . ((:block 2)))
     ("POST" . ((:block 2)))
     ("PUT" . ((:block 2)))
     ("DELETE" . ((:block 2)))
     ("HEAD" . ((:block 2)))
     ("ANY" . ((:block 2)))
     ("OPTIONS" . ((:block 2)))
     ("PATCH" . ((:block 2)))
     ("rfn" . ((:block 2)))
     ("let-routes" . ((:block 1)))
     ("context" . ((:block 2)))))
  :config
  ;; 缩进设置 (clojure-mode，cider 等仍会用到)
  (setq clojure-indent-style 'align-arguments
        clojure-align-forms-automatically t)

  ;; 自定义缩进规则
  (with-eval-after-load 'clojure-mode
    (define-clojure-indent
     (defroutes 'defun)
     (GET 2)
     (POST 2)
     (PUT 2)
     (DELETE 2)
     (HEAD 2)
     (ANY 2)
     (OPTIONS 2)
     (PATCH 2)
     (rfn 2)
     (let-routes 1)
     (context 2))))

;; =============================================================================
;; CIDER - Clojure 交互式开发环境
;; =============================================================================

;; 使用 EGLOT 管理 xref 跳转
;;(setq cider-use-xref nil) ;; 在这里设置不起作用，因为是 defcustom 定义的，应该要在 custom-set-varialbes 里

(use-package cider
  :ensure t
  :defer t
  :commands (cider-jack-in cider-connect)
  :bind (:map cider-mode-map
              ("C-c C-d" . cider-doc)
              ("C-c C-j" . cider-javadoc)
              ("C-c M-." . cider-find-var)
              ("C-c M-," . cider-pop-back))
  ;; cider 2.0 起 C-c C-t 是 cider-test-menu (transient)，其中 n/p/t 即下面三个命令；
  ;; 再绑定 C-c C-t n 会报 "non-prefix key" 并中断 cider 加载
  ;; ("C-c C-t n" . cider-test-run-ns-tests)
  ;; ("C-c C-t p" . cider-test-run-project-tests)
  ;; ("C-c C-t t" . cider-test-run-test)
  :init
  :custom
  ;; 不要操作我的 xref，我用 EGLOT 管理
  (cider-use-xref nil)
  :config
  ;; REPL 配置
  (setq
   cider-repl-display-help-banner nil
   cider-repl-pop-to-buffer-on-connect 'display-only
   cider-repl-use-pretty-printing t
   cider-repl-result-prefix ";; => "
   cider-repl-history-size 1000
   cider-repl-history-file (expand-file-name "cider-history" user-emacs-directory))

  ;; 自动保存 REPL 历史：设置了 cider-repl-history-file 后 cider 自己会在
  ;; kill-buffer-hook / kill-emacs-hook 中保存 (cider-repl-history-save-all)
  ;; (add-hook 'kill-emacs-hook
  ;;   (lambda ()
  ;;     (when (and (fboundp 'cider-repl-history-save)
  ;;             cider-repl-history-file)
  ;;       (cider-repl-history-save))))

  ;; 不要操作我的 M-. 那是 xref 的快捷键
  (keymap-set cider-mode-map "M-." nil)
  (keymap-set cider-mode-map "M-," nil)

  ;; 补全配置
  (setq cider-prompt-for-symbol nil
        cider-completion-use-context t)

  ;; 启动配置
  (setq cider-auto-select-error-buffer t
        cider-auto-select-test-report-buffer t
        cider-prefer-local-resources t
        cider-save-file-on-load t
        cider-font-lock-dynamically '(macro core function var))

  ;; 测试配置
  (setq cider-test-show-report-on-success t
        cider-auto-test-mode t)

  ;; eldoc 配置
  (setq cider-eldoc-display-for-symbol-at-point t
        cider-eldoc-display-context-dependent-info t)

  ;; 连接配置
  (setq nrepl-log-messages t
        nrepl-hide-special-buffers t)

  ;; 格式化代码快捷键
  (keymap-set cider-mode-map "C-c C-f" #'cider-format-buffer))

;; =============================================================================
;; CIDER REPL 增强
;; =============================================================================

(use-package cider-repl
  :ensure nil
  :after cider
  :config
  ;; REPL 快捷键
  (keymap-set cider-repl-mode-map "C-c C-o" #'cider-repl-clear-buffer)
  (keymap-set cider-repl-mode-map "C-c M-o" #'cider-repl-clear-output))

;; =============================================================================
;; clj-kondo 集成
;; =============================================================================

(use-package flycheck-clj-kondo
  :ensure t
  :after (flycheck clojure-ts-mode))

;; =============================================================================
;; 自定义函数
;; =============================================================================

(defun my-cider-repl-reset ()
  "Reset the CIDER REPL namespace."
  (interactive)
  (cider-interactive-eval "(user/reset)"))

(defun my-cider-refresh ()
  "Refresh changed namespaces."
  (interactive)
  (cider-interactive-eval "(clojure.tools.namespace.repl/refresh)"))

;; 快捷键绑定
(with-eval-after-load 'cider
  (keymap-set cider-mode-map "C-c C-r r" #'my-cider-repl-reset)
  (keymap-set cider-mode-map "C-c C-r f" #'my-cider-refresh))

;; Old names, so M-x my/... still works.
(define-obsolete-function-alias 'my/cider-refresh #'my-cider-refresh "2026-10-27")
(define-obsolete-function-alias 'my/cider-repl-reset #'my-cider-repl-reset "2026-10-27")

(provide 'init-lang-clojure)

;;; init-lang-clojure.el ends here
