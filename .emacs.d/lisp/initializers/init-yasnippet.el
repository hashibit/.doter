;;; -*- lexical-binding: t -*-
(require 'my-toggle-code-intelligence)






(declare-function yas-abort-snippet "yasnippet")

(defun my-abort-yas-before-format (&rest _)
  "在格式化前中止所有活跃的 YASnippet 会话。"
  (when (bound-and-true-p yas-minor-mode)
    (yas-abort-snippet)))

(use-package yasnippet
  ;; Load with the first prog-mode buffer, not at startup.
  :hook (prog-mode . yas-minor-mode)
  :config

  (add-hook 'yas-before-expand-snippet-hook #'my-disable-eglot-highlight)
  (add-hook 'yas-after-exit-snippet-hook    #'my-enable-eglot-highlight)

  ;; 为 format-all 的格式化命令添加 advice
  (advice-add 'format-all-buffer :before #'my-abort-yas-before-format)
  (advice-add 'format-all-region :before #'my-abort-yas-before-format)
  ;; format-all-mode 会自动注册这个函数到 before-save-hook
  (advice-add 'format-all--buffer-from-hook :before #'my-abort-yas-before-format)
  ;; 为 eglot 的格式化命令添加 advice
  (advice-add 'eglot-format-buffer :before #'my-abort-yas-before-format)
  (advice-add 'eglot-format-region :before #'my-abort-yas-before-format)
  ;; Face configuration moved to custom-set-faces
  )


(provide 'init-yasnippet)
