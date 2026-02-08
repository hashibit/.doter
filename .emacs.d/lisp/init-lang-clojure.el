;;; init-lang-clojure.el --- Clojure development configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Clojure 开发环境配置

;;; Code:

;; =============================================================================
;; Clojure Mode (使用 treesit)
;; =============================================================================

(use-package clojure-ts-mode
  :ensure t
  :mode (("\\.clj\\'" . clojure-ts-mode)
          ("\\.cljs\\'" . clojure-ts-mode)
          ("\\.cljc\\'" . clojure-ts-mode)
          ("\\.edn\\'" . clojure-ts-mode))
  :config
  ;; 缩进设置
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
          ("C-c M-," . cider-pop-back)
          ("C-c C-t n" . cider-test-run-ns-tests)
          ("C-c C-t p" . cider-test-run-project-tests)
          ("C-c C-t t" . cider-test-run-test))
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

  ;; 自动保存 REPL 历史
  (add-hook 'kill-emacs-hook
    (lambda ()
      (when (and (fboundp 'cider-repl-history-save)
              cider-repl-history-file)
        (cider-repl-history-save))))

  ;; 不要操作我的 M-. 那是 xref 的快捷键
  (add-hook 'cider-mode-hook
    (lambda()
      (define-key cider-mode-map (kbd "M-.") nil)
      (define-key cider-mode-map (kbd "M-,") nil)
      ))

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
  (define-key cider-mode-map (kbd "C-c C-f") #'cider-format-buffer)
  )

;; =============================================================================
;; CIDER REPL 增强
;; =============================================================================

(use-package cider-repl
  :ensure nil
  :after cider
  :config
  ;; REPL 快捷键
  (define-key cider-repl-mode-map (kbd "C-c C-o") #'cider-repl-clear-buffer)
  (define-key cider-repl-mode-map (kbd "C-c M-o") #'cider-repl-clear-output))

;; =============================================================================
;; clj-kondo 集成
;; =============================================================================

(use-package flycheck-clj-kondo
  :ensure t
  :after (flycheck clojure-ts-mode))

;; =============================================================================
;; 自定义函数
;; =============================================================================

(defun my/cider-repl-reset ()
  "Reset the CIDER REPL namespace."
  (interactive)
  (cider-interactive-eval "(user/reset)"))

(defun my/cider-refresh ()
  "Refresh changed namespaces."
  (interactive)
  (cider-interactive-eval "(clojure.tools.namespace.repl/refresh)"))

;; 快捷键绑定
(with-eval-after-load 'cider
  (define-key cider-mode-map (kbd "C-c C-r r") #'my/cider-repl-reset)
  (define-key cider-mode-map (kbd "C-c C-r f") #'my/cider-refresh)
  )

(provide 'init-lang-clojure)

;;; init-lang-clojure.el ends here
