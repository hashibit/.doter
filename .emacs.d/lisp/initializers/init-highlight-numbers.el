;; -*- lexical-binding: t -*-
;;; init-highlight-numbers.el --- Highlight Numbers Configuration

;;; Commentary:
;;
;;  Highlight numeric literals in programming modes
;;

;;; Code:

(use-package highlight-numbers
  :ensure t
  :hook (prog-mode . highlight-numbers-mode))

(provide 'init-highlight-numbers)

;;; init-highlight-numbers.el ends here