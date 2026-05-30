;; -*- lexical-binding: t -*-
;;; init-electric.el --- Electric Mode Configuration

;;; Commentary:
;;
;;  Automatic electric features like pair matching and indentation
;;

;;; Code:

(use-package electric
  :ensure t
  :demand t
  :config
  (electric-pair-mode -1)
  (electric-indent-mode -1))

(add-hook 'prog-mode-hook #'electric-indent-local-mode)


(provide 'init-electric)

;;; init-electric.el ends here
