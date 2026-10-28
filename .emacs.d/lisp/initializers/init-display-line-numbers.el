;; -*- lexical-binding: t -*-
;;; init-display-line-numbers.el --- Line number configuration

;;; Code:

(use-package display-line-numbers
  :defer t
  :config
  ;; line number fixed width
  (setq-default display-line-numbers-width-start 1000)
  (setq-default display-line-numbers-grow-only t)
  :hook
  (prog-mode . display-line-numbers-mode)
  (markdown-mode . display-line-numbers-mode)
  (nxml-mode . display-line-numbers-mode)
  (yaml-mode . display-line-numbers-mode)
  (conf-mode . display-line-numbers-mode))



(provide 'init-display-line-numbers)

;;; init-display-line-numbers.el ends here
