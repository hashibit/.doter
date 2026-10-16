;; -*- lexical-binding: t -*-
;;; init-srefactor.el --- SRefactor Configuration

;;; Commentary:
;;
;;  Semantic refactoring for C/C++ code
;;

;;; Code:

(use-package srefactor
  :ensure t
  :demand t
  :config
  (semantic-mode 1) ;; -> this is optional for Lisp
  ;; semantic 只解析 cc-mode (c-mode/c++-mode)，c-ts-mode 下无效，所以不绑定 ts mode map
  (keymap-set c-mode-map "M-RET" #'srefactor-refactor-at-point)
  (keymap-set c++-mode-map "M-RET" #'srefactor-refactor-at-point))

(provide 'init-srefactor)

;;; init-srefactor.el ends here