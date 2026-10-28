;; -*- lexical-binding: t -*-
;;; init-yank-indent.el --- Yank Indent Configuration

;;; Commentary:
;;
;;  Automatically indent yanked text
;;

;;; Code:

(use-package yank-indent
  :ensure t
  :demand t
  :config
  (global-yank-indent-mode 1))

(provide 'init-yank-indent)

;;; init-yank-indent.el ends here