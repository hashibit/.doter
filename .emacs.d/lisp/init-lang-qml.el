;; -*- lexical-binding: t -*-
;;; init-lang-qml.el --- QML Language Configuration

;;; Commentary:
;;
;;  QML language support for Qt development
;;

;;; Code:

(use-package qml-mode
  :ensure t
  :hook
  (qml-mode . (lambda ()
                (setq js-indent-level 4)
                (c-ts-mode-toggle-comment-style -1)
                (bind-keys :map qml-mode-map ("C-c C-b" . compile))
                (bind-keys :map qml-mode-map ("s-b" . compile))))
  (qml-mode . maybe-cmake-project-mode)
  (qml-mode . (lambda() (format-all-mode -1)))
  :config
  (add-to-list 'auto-mode-alist '("\\.qml\\'" . qml-mode)))

(provide 'init-lang-qml)

;;; init-lang-qml.el ends here