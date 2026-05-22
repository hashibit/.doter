;; -*- lexical-binding: t -*-
;;; init-eglot.el --- Language Server Protocol client eglot configuration

;;; Commentary:
;;
;;  Language Server Protocol Emacs Client Eglot
;;

;;; Code:

(require 'my-utils)

;; Increase the amount of data which Emacs reads from the process
(when (bound-and-true-p read-process-output-max)
  (setq read-process-output-max (* 1024 1024)))





(use-package eglot
  :ensure t
  :commands (eglot eglot-ensure)
  :custom
  (eglot-code-action-indicator "")

  :hook
  ;; Enable eglot for various programming languages
  ((c-ts-mode c++-ts-mode) . eglot-ensure)

  ((go-mode go-ts-mode) . (lambda()
                            (setq eglot-workspace-configuration
                              '((gopls (usePlaceholders . t))))
                            (eglot-ensure)))

  ;; (python-ts-mode . eglot-ensure)
  (python-ts-mode . (lambda ()
                      (my-python-eglot-setup)
                      (eglot-ensure)))

  (zig-mode . eglot-ensure)
  (tsx-ts-mode . eglot-ensure)
  (clojure-ts-mode . eglot-ensure)

  (swift-mode . (lambda ()
                  (unless (and buffer-file-name
                            (string= (file-name-extension buffer-file-name) "swiftinterface"))
                    (eglot-ensure))))

  ((rust-mode rust-ts-mode) . (lambda ()
                               (setq-local eglot-workspace-configuration
                                 '(:rust-analyzer
                                    ( :checkOnSave (:enable :json-false)
                                      :procMacro (:enable t)
                                      :cargo ( :buildScripts (:enable t)
                                               :features "all")
                                      :diagnostics (:experimental (:enable :json-false))
                                      :completion (:autoimport (:enable t))
                                      :files (:watcher "server"))))
                               (eglot-ensure)))

  :config

  (cl-defmethod eglot-register-capability
    (_server (_method (eql workspace/didChangeWatchedFiles)) _id &key watchers)
    (ignore watchers)
    (list t "client-side watch refused; server polls"))

  (defun my-python-locate-venv ()
  "Locate the local virtualenv Python executable using project.el and uv standards."
  (when-let* ((project (project-current))
              (project-root (project-root project))
              ;; 优先查找项目根目录下的 .venv (uv 的默认行为)
              (venv-dir (expand-file-name ".venv/" project-root))
              (python-exec (expand-file-name "bin/python" venv-dir)))
    (when (file-executable-p python-exec)
      python-exec)))

  (defun my-python-eglot-setup ()
    "Set up Eglot workspace configuration for Python using local venv."
    (if-let ((venv-python (my-python-locate-venv)))
      (progn
        (message "✅ Eglot: Using project venv Python: %s" venv-python)
        (setq-local eglot-workspace-configuration
          `(:python
             (:pythonPath ,venv-python)
             :python.analysis
             (:logLevel "trace")))
        ;; 可选：激活 pyvenv
        (when (bound-and-true-p pyvenv-mode)
          (pyvenv-activate (file-name-directory (directory-file-name venv-python)))))
      ;; 回退机制：没找到本地虚拟环境则清除临时配置
      (setq-local eglot-workspace-configuration nil)
      (message "ℹ️ Eglot: No local .venv found, using fallback/global server.")))

  ;; Swift: use .xcodeproj directory as project root for sourcekit-lsp.
  ;; Without this, monorepo git root becomes rootUri and sourcekit-lsp
  ;; can't resolve SPM dependencies or cross-reference project files.
  (defun my-swift-project-try (dir)
    "Project backend: find nearest directory containing .xcodeproj."
    (when (and dir
            (buffer-file-name)
            (string-match-p "\\.swift\\'" (buffer-file-name)))
      (let ((found nil)
            (current dir))
        (while (and current (not found))
          (let ((match (directory-files current nil "\\.xcodeproj\\'" t)))
            (if match
              (setq found current)
              (let ((parent (file-name-directory (directory-file-name current))))
                (if (string= parent current)
                  (setq current nil)
                  (setq current parent))))))
        (when found
          (cons 'transient found)))))
  (add-hook 'project-find-functions #'my-swift-project-try)

  (defun my-rust-project-root (dir)
    "Find the topmost Cargo.toml workspace root, stopping at filesystem root."
    (let ((found nil)
          (current (locate-dominating-file dir "Cargo.toml")))
      (while current
        (setq found current)
        (let ((parent (file-name-directory (directory-file-name current))))
          (if (string= parent current)
            (setq current nil)  ; filesystem root, stop
            (setq current (locate-dominating-file parent "Cargo.toml")))))
      found))

  (defun my-rust-project-try (dir)
    "Project backend that returns the topmost Cargo workspace root."
    (when (and dir
            (buffer-file-name)
            (string-match-p "\\.rs\\'" (buffer-file-name))
            (locate-dominating-file dir "Cargo.toml"))
      (when-let ((root (my-rust-project-root dir)))
        (cons 'transient root))))
  (add-hook 'project-find-functions #'my-rust-project-try)

  (defvar my-eglot-ensure-is-enabled t
    "控制是否允许 eglot-ensure 实际运行。")
  (defun my-toggle-eglot-ensure () (interactive) (setq my-eglot-ensure-is-enabled (not my-eglot-ensure-is-enabled)))
  (defun my/around-eglot-ensure (orig-fun &rest args)
    "根据开关决定是否真正调用 eglot-ensure。"
    (if my-eglot-ensure-is-enabled
      (apply orig-fun args)
      (message "[Eglot] eglot-ensure 已被阻止，使用 symbol-overlay-mode 代替高亮")
      (symbol-overlay-mode 1)
      ))
  (advice-add 'eglot-ensure :around #'my/around-eglot-ensure)

  ;; Face configuration moved to custom-set-faces

  ;; Server configurations for specific languages

  ;; Configure gopls
  (add-to-list 'eglot-server-programs
    '(go-ts-mode . ("gopls")))

  ;; Configure clangd parameters
  (add-to-list 'eglot-server-programs
    '((c++-mode c-mode c++-ts-mode c-ts-mode) . ("clangd"
                                                  "--compile-commands-dir=build"
                                                  ;; "--background-index"
                                                  "--header-insertion=never"
                                                  "--log=error"
                                                  ))
    )

  ;; Swift-specific server configuration
  (add-to-list 'eglot-server-programs '(swift-mode . ("xcrun" "sourcekit-lsp")))

  ;; Python server configuration
  (add-to-list 'eglot-server-programs '(python-ts-mode . ("basedpyright-langserver" "--stdio")))

  ;; 自定义查找引用行为：不包含定义
  (cl-defmethod xref-backend-references ((_backend (eql eglot)) _identifier)
    (or
      eglot--lsp-xref-refs
      (eglot--lsp-xrefs-for-method
        :textDocument/references
        :extra-params `(:context (:includeDeclaration :json-false)))))

  ;; Swift hook moved to :hook section above

  ;; Don't interfere with company configuration
  (setq eglot-stay-out-of '(company))
  ;; Don't show indicator
  ;; Performance and behavior settings
  (setq eglot-autoshutdown t
    eglot-ignored-server-capabilities '(:foldingRangeProvider)
    ;; Drop jsonrpc log to improve performance
    eglot-events-buffer-size 1)

  ;; Disable inlay hints by default
  (add-hook 'eglot-managed-mode-hook (lambda () (eglot-inlay-hints-mode -1))))


;; (use-package sideline
;;   :ensure t
;;   :after eglot
;;   :hook (prog-mode . sideline-mode)
;;   :config
;;   (setq sideline-backends-right '(sideline-flymake)
;;     sideline-eglot-code-actions-prefix "-> ")
;;   )
;;
;; (use-package sideline-flymake
;;   :ensure t
;;   :after sideline
;;   )

(provide 'init-eglot)

;;; init-eglot.el ends here
