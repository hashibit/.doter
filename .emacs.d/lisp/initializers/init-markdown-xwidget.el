;; -*- lexical-binding: t -*-
;;; init-markdown-xwidget.el --- Markdown-xwidget preview configuration

;;; Code:

;; Package variables, declared for the byte compiler.
(defvar markdown-xwidget-command)
(defvar markdown-xwidget-github-theme)
(defvar markdown-xwidget-mermaid-theme)
(defvar markdown-xwidget-code-block-theme)
(defvar markdown-mode-command-map)

(use-package markdown-xwidget
  :after markdown-ts-mode
  :config
  (setq markdown-xwidget-command nil
        markdown-xwidget-github-theme "light"
        markdown-xwidget-mermaid-theme "default"
        markdown-xwidget-code-block-theme "default")
  :bind (:map markdown-mode-command-map
              ("x" . markdown-xwidget-preview-mode)))


(provide 'init-markdown-xwidget)

;;; init-markdown-xwidget.el ends here
