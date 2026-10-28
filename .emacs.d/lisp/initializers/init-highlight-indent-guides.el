;; -*- lexical-binding: t -*-
;;; init-highlight-indent-guides.el --- Highlight Indent Guides Configuration

;;; Commentary:
;;
;;  Visual indentation guides for programming modes
;;

;;; Code:

(use-package highlight-indent-guides
  :ensure t
  :config
  (setq highlight-indent-guides-method 'character
        highlight-indent-guides-auto-enabled nil
        ;; highlight-indent-guides-character ?\x258f
        ;; highlight-indent-guides-character ?\x250A
        highlight-indent-guides-character ?\x2506
        )

  ;; Face configuration moved to custom-set-faces
  (defun my-highlighter (level responsive display)
    (if (> 1 level)
        nil
      (highlight-indent-guides--highlighter-default level responsive display)))
  (setq highlight-indent-guides-highlighter-function 'my-highlighter)
  :hook (prog-mode . highlight-indent-guides-mode))

(provide 'init-highlight-indent-guides)

;;; init-highlight-indent-guides.el ends here
