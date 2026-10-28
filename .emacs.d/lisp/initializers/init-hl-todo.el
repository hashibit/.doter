;; -*- lexical-binding: t -*-
;;; init-hl-todo.el --- Hl-todo Configuration

;;; Commentary:
;;
;;  Highlight TODO keywords
;;

;;; Code:

(use-package hl-todo
  :ensure t
  :config
  (global-hl-todo-mode 1)
  )

(provide 'init-hl-todo)

;;; init-hl-todo.el ends here
