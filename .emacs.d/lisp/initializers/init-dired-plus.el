;; -*- lexical-binding: t -*-
;;; init-dired-plus.el --- Dired+ Configuration

;;; Commentary:
;;
;;  Enhanced dired functionality
;;

;;; Code:

(use-package dired+
  :ensure nil
  :demand t
  :init
  (setq diredp-hide-details-initially-flag nil))

(provide 'init-dired-plus)

;;; init-dired-plus.el ends here