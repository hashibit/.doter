;; -*- lexical-binding: t -*-
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

