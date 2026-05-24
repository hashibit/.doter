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


(use-package go-ts-mode
  :ensure t
  :mode ("\\.go\\'" . go-ts-mode)
  :init
  (add-hook 'go-ts-mode-hook #'eglot-ensure)
  (add-hook 'go-ts-mode-hook #'(lambda() (highlight-indent-guides-mode -1)))
  ;; 只用 eglot-format-buffer（见 my-go-before-save），关掉 format-all 避免双重格式化
  (add-hook 'go-ts-mode-hook #'(lambda() (format-all-mode -1)))
  :config
  (setq go-ts-mode-indent-offset 4)
  (defun my-go-mode-split-string(arg)
    "Split Go string expressions with appropriate formatting."
    (interactive "*P")
    (sp-split-sexp arg)
    (insert-char 43) ; insert char +
    (newline)
    (forward-char)
    )

  (defun my-go-before-save ()
    (when (derived-mode-p 'go-ts-mode)
      ;; 整理 imports（作用于整个 buffer）
      (eglot-code-action-organize-imports (point-min) (point-max))
      ;; 或者模拟交互式, 自动传point (call-interactively #'eglot-code-action-organize-imports)
      (eglot-format-buffer)))

  (add-hook 'before-save-hook #'my-go-before-save)

  (with-eval-after-load 'exec-path-from-shell
    (exec-path-from-shell-copy-envs '("GOPATH" "GO111MODULE" "GOPROXY")))

  ;; Key bindings
  (define-key go-ts-mode-map (kbd "s-<return>") #'my-go-mode-split-string)
  (sp-local-pair 'prog-mode "{" nil :post-handlers '((indent-between-pair "RET")))
  )

(provide 'init-lang-go)

;;; init-lang-go.el ends here
