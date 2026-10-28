;; -*- lexical-binding: t -*-
;;; init-rainbow-delimiters.el --- Rainbow Delimiters Configuration

;;; Commentary:
;;
;;  Colorize parentheses, brackets, and braces
;;

;;; Code:

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

(provide 'init-rainbow-delimiters)

;;; init-rainbow-delimiters.el ends here