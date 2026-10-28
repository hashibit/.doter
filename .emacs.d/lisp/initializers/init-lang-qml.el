;; -*- lexical-binding: t -*-
;;; init-lang-qml.el --- QML Language Configuration

;;; Commentary:
;;
;;  QML language support for Qt development
;;

;;; Code:

(defvar js-indent-level)

(defun my-qml-mode-setup ()
  "Buffer-local setup for `qml-mode'."
  (setq-local js-indent-level 4)
  ;; line comment, double forward slash
  (setq-local comment-start "// "
              comment-end "")
  (format-all-mode -1))

(use-package qml-mode
  :ensure t
  :mode "\\.qml\\'"
  :hook
  (qml-mode . my-qml-mode-setup)
  (qml-mode . maybe-cmake-project-mode)
  :bind (:map qml-mode-map
              ("C-c C-b" . compile)
              ("s-b" . compile)))

(provide 'init-lang-qml)

;;; init-lang-qml.el ends here