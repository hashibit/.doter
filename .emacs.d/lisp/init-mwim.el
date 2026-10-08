;; -*- lexical-binding: t -*-
;;; init-mwim.el --- MWIM Configuration

;;; Commentary:
;;
;;  Move Where I Mean - improved line beginning and end movement
;;

;;; Code:

(use-package mwim
  :ensure t
  :demand t
  :config
  (keymap-global-set "<remap> <move-end-of-line>" #'mwim-end-of-code-or-line)
  (keymap-global-set "<remap> <move-beginning-of-line>" #'mwim-beginning-of-code-or-line))

(provide 'init-mwim)

;;; init-mwim.el ends here