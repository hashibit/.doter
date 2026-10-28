;; -*- lexical-binding: t -*-
;;; init-lang-go.el --- Go Lang Config

;; Author: Zsxh Chen <bnbvbchen@gmail.com>
;; URL: https://github.com/zsxh/emacs.d

;;; Commentary:
;;
;;  Go Lang Config
;;

;;; Code:

;; Install gopls
;; https://github.com/golang/tools/blob/master/gopls/doc/user.md#installation


(declare-function eglot-managed-p "eglot")
(declare-function eglot-format-buffer "eglot")
(declare-function eglot-code-action-organize-imports "eglot")
(declare-function sp-split-sexp "smartparens")

(defun my-go-before-save ()
  (when (and (derived-mode-p 'go-ts-mode)
             (fboundp 'eglot-managed-p)
             (eglot-managed-p))
    ;; 整理 imports（作用于整个 buffer）
    (ignore-errors (eglot-code-action-organize-imports (point-min) (point-max)))
    ;; 或者模拟交互式, 自动传point (call-interactively #'eglot-code-action-organize-imports)
    (eglot-format-buffer)))

(defun my-go-ts-mode-setup ()
  "Buffer-local setup for `go-ts-mode'."
  (highlight-indent-guides-mode -1)
  ;; 只用 eglot-format-buffer（见 my-go-before-save），关掉 format-all 避免双重格式化
  (format-all-mode -1)
  (add-hook 'before-save-hook #'my-go-before-save nil t))

(use-package go-ts-mode
  :ensure t
  :mode ("\\.go\\'" . go-ts-mode)
  ;; eglot-ensure 由 init-eglot 的 :hook 负责
  :hook (go-ts-mode . my-go-ts-mode-setup)
  :bind (:map go-ts-mode-map
              ("s-<return>" . my-go-mode-split-string))
  :config
  (setq go-ts-indent-offset 4)
  (defun my-go-mode-split-string(arg)
    "Split Go string expressions with appropriate formatting."
    (interactive "*P")
    (sp-split-sexp arg)
    (insert-char 43) ; insert char +
    (newline)
    (forward-char))

  (with-eval-after-load 'exec-path-from-shell
    (exec-path-from-shell-copy-envs '("GOPATH" "GO111MODULE" "GOPROXY")))

  ;; indent-between-pair 未定义（smartparens 会静默忽略），且作用于全部 prog-mode；
  ;; { RET 的缩进已在 init-smartparens 中配置
  ;; (sp-local-pair 'prog-mode "{" nil :post-handlers '((indent-between-pair "RET")))
  )

(provide 'init-lang-go)

;;; init-lang-go.el ends here
