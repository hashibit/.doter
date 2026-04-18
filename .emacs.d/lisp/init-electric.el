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


(provide 'init-electric)

;;; init-electric.el ends here
