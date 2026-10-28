;; -*- lexical-binding: t -*-
;;; init-eglot.el --- Language Server Protocol client eglot configuration

;;; Commentary:
;;
;;  Language Server Protocol Emacs Client Eglot
;;
;;  Layout:
;;    1. Helpers: Python venv, start functions, on/off switch,
;;       project backends, workspace configuration, Markdown preview.
;;    2. `use-package eglot': options, hooks, servers, overrides.
;;

;;; Code:

(require 'my-utils)

(declare-function eglot-current-server "eglot")
(declare-function eglot-execute "eglot")
(declare-function eglot--lsp-xrefs-for-id "eglot")
(declare-function pyvenv-activate "pyvenv")
(defvar markdown-mode-map)

;; early-init.el already sets read-process-output-max to 1 MiB.
;; ;; Increase the amount of data which Emacs reads from the process
;; (when (bound-and-true-p read-process-output-max)
;;   (setq read-process-output-max (* 1024 1024)))


;;; Python

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
  "Report which Python Eglot will use and activate the local venv.
Server settings come from `my-eglot-workspace-configuration'."
  (if-let* ((venv-python (my-python-locate-venv)))
      (progn
        (message "✅ Eglot: Using project venv Python: %s" venv-python)
        ;; 可选：激活 pyvenv
        (when (bound-and-true-p pyvenv-mode)
          (pyvenv-activate (file-name-directory (directory-file-name venv-python)))))
    (message "ℹ️ Eglot: No local .venv found, using fallback/global server.")))

(defun my-python-eglot-ensure ()
  "Set up the Python venv, then start Eglot."
  (my-python-eglot-setup)
  (eglot-ensure))


;;; Start functions

(defun my-swift-eglot-ensure ()
  "Start Eglot for Swift buffers, except .swiftinterface files."
  (unless (and buffer-file-name
               (string= (file-name-extension buffer-file-name) "swiftinterface"))
    (eglot-ensure)))

;; 延迟启动 eglot，避免打开文件时同步等待 LSP 初始化导致卡顿。
;; TypeScript/TSX 项目的 typescript-language-server 启动和分析较慢，
;; 用 idle timer 让文件先显示出来，LSP 在 Emacs 空闲时再连。
(defun my-eglot--ensure-in-buffer (buffer)
  "Call `eglot-ensure' in BUFFER if it is still live."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (eglot-ensure))))

(defun my-eglot-ensure-deferred ()
  "Call `eglot-ensure' after a short idle period so file opens instantly."
  (run-with-idle-timer 0.3 nil #'my-eglot--ensure-in-buffer (current-buffer)))


;;; On/off switch for eglot-ensure

(defvar my-eglot-ensure-is-enabled t
  "控制是否允许 eglot-ensure 实际运行。")

(defun my-toggle-eglot-ensure ()
  "Toggle `my-eglot-ensure-is-enabled'."
  (interactive)
  (setq my-eglot-ensure-is-enabled (not my-eglot-ensure-is-enabled)))

(defun my-eglot-ensure-maybe-block (orig-fun &rest args)
  "根据开关决定是否真正调用 eglot-ensure。
Around advice for ORIG-FUN (`eglot-ensure') with ARGS."
  (if my-eglot-ensure-is-enabled
      (apply orig-fun args)
    (message "[Eglot] eglot-ensure 已被阻止，使用 symbol-overlay-mode 代替高亮")
    (symbol-overlay-mode 1)))


;;; Project backends

;; Swift: use .xcodeproj directory as project root for sourcekit-lsp.
;; Without this, monorepo git root becomes rootUri and sourcekit-lsp
;; can't resolve SPM dependencies or cross-reference project files.
(defun my-swift-project-try (dir)
  "Project backend: find nearest directory containing .xcodeproj."
  (when (and dir
             (buffer-file-name)
             (string-match-p "\\.swift\\'" (buffer-file-name)))
    (when-let* ((found (locate-dominating-file
                        dir
                        (lambda (d)
                          (ignore-errors
                            (directory-files d nil "\\.xcodeproj\\'" t 1))))))
      (cons 'transient found))))

(defun my-rust-project-root (dir)
  "Find the topmost Cargo.toml workspace root, stopping at filesystem root."
  (let ((found nil)
        (current (locate-dominating-file dir "Cargo.toml")))
    (while current
      (setq found current)
      (let ((parent (file-name-directory (directory-file-name current))))
        (if (string= parent current)
            (setq current nil)          ; filesystem root, stop
          (setq current (locate-dominating-file parent "Cargo.toml")))))
    found))

(defun my-rust-project-try (dir)
  "Project backend that returns the topmost Cargo workspace root."
  (when (and dir
             (buffer-file-name)
             (string-match-p "\\.rs\\'" (buffer-file-name))
             (locate-dominating-file dir "Cargo.toml"))
    (when-let* ((root (my-rust-project-root dir)))
      (cons 'transient root))))


;;; Workspace configuration

(defun my-eglot-workspace-configuration (_server)
  "Return the workspace configuration plist for every Eglot server.
Eglot calls this with `default-directory' bound to the project root."
  (let ((venv-python (expand-file-name ".venv/bin/python")))
    `(:gopls (:usePlaceholders t)
      :rust-analyzer
      ( :checkOnSave (:enable :json-false)
        :procMacro (:enable t)
        :cargo ( :buildScripts (:enable t)
                 :features "all")
        :diagnostics (:experimental (:enable :json-false))
        :completion (:autoimport (:enable t))
        :files (:watcher "server"))
      ,@(when (file-executable-p venv-python)
          `(:python (:pythonPath ,venv-python)
            :python.analysis (:logLevel "trace"))))))


;;; Markdown preview (mpls)

(defun my-eglot-mpls-open-preview ()
  "调用 mpls 语言服务器打开 Markdown 预览"
  (interactive)
  (if (eglot-current-server)
      ;; 向 mpls 发送打开预览的自定义命令
      (eglot-execute (eglot-current-server)
                     '(:command "open-preview" :arguments []))
    (message "Eglot 未在该缓冲区启动")))


;;; Eglot

(use-package eglot
  :ensure t
  :commands (eglot eglot-ensure)

  :init
  ;; Don't interfere with company configuration.
  ;; eglot-stay-out-of is a plain variable, so :custom does not set it.
  (setq eglot-stay-out-of '(company))

  :custom
  (eglot-code-action-indicator "")
  ;; Shut down a server when its last buffer is killed
  (eglot-autoshutdown t)
  ;; Disable folding ranges and inlay hints
  (eglot-ignored-server-capabilities '(:foldingRangeProvider :inlayHintProvider))
  ;; Drop jsonrpc log to improve performance
  (eglot-events-buffer-config '(:size 0 :format full))

  :hook
  ;; Start at once
  ((c-ts-mode c++-ts-mode
    go-mode go-ts-mode
    rust-mode rust-ts-mode
    zig-mode
    clojure-ts-mode
    markdown-mode) . eglot-ensure)
  ;; Start when Emacs is idle (slow servers)
  ((js-ts-mode typescript-ts-mode tsx-ts-mode
    jtsx-jsx-mode jtsx-typescript-mode jtsx-tsx-mode) . my-eglot-ensure-deferred)
  ;; Start with a language-specific check first
  ;; (python-ts-mode . eglot-ensure)
  (python-ts-mode . my-python-eglot-ensure)
  (swift-mode . my-swift-eglot-ensure)

  :config
  ;; Servers
  ;; gopls is in the default eglot-server-programs (go-mode/go-ts-mode).
  (add-to-list 'eglot-server-programs
               '((c++-mode c-mode c++-ts-mode c-ts-mode)
                 . ("clangd"
                    "--compile-commands-dir=build"
                    ;; "--background-index"
                    "--header-insertion=never"
                    "--log=error")))
  (add-to-list 'eglot-server-programs
               '(swift-mode . ("xcrun" "sourcekit-lsp")))
  ;; Markdown: do not auto preview. Preview by hand with C-c C-p.
  (add-to-list 'eglot-server-programs
               '(markdown-mode . ("mpls" "--tabs" "--no-auto")))
  (add-to-list 'eglot-server-programs
               '(python-ts-mode . ("basedpyright-langserver" "--stdio")))

  ;; gopls / rust-analyzer / python settings
  (setq-default eglot-workspace-configuration #'my-eglot-workspace-configuration)

  ;; Project roots
  (add-hook 'project-find-functions #'my-swift-project-try)
  (add-hook 'project-find-functions #'my-rust-project-try)

  ;; Keys and switch
  (with-eval-after-load 'markdown-mode
    (keymap-set markdown-mode-map "C-c C-p" #'my-eglot-mpls-open-preview))
  (advice-add 'eglot-ensure :around #'my-eglot-ensure-maybe-block)

  ;; Overrides
  ;; 性能取舍：拒绝所有 server 的 didChangeWatchedFiles 注册，让 server 自己轮询
  (cl-defmethod eglot-register-capability
    (_server (_method (eql workspace/didChangeWatchedFiles)) _id &key watchers)
    (ignore watchers)
    (list t "client-side watch refused; server polls"))

  ;; 自定义查找引用行为：不包含定义
  ;; 注意：依赖 eglot 内部实现 (eglot--lsp-xrefs-for-id)，升级 eglot 后可能失效
  (cl-defmethod xref-backend-references ((_backend (eql eglot)) id)
    (eglot--lsp-xrefs-for-id
     id :textDocument/references
     :extra-args `(:context (:includeDeclaration :json-false)))))


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
