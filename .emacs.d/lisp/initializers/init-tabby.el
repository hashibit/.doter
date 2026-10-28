;; -*- lexical-binding: t -*-
;;; init-tabby.el --- Tabby Configuration

;;; Commentary:
;;
;;  Tabby AI completion configuration
;;

;;; Code:

;; Package variables, declared for the byte compiler.
(defvar tabby-completion-map)

(use-package tabby
  :ensure nil
  :demand t
  :hook (python-ts-mode . tabby-mode)
  :bind (:map tabby-completion-map
              ("M-<tab>" . tabby-accept-completion)))

(provide 'init-tabby)

;;; init-tabby.el ends here