;; -*- lexical-binding: t -*-
;;; init-dired-plus.el --- Dired+ Configuration

;;; Commentary:
;;
;;  Enhanced dired functionality
;;

;;; Code:

(use-package dired+
  :ensure nil
  ;; Load with dired, not at startup.
  :after dired
  :init
  (setq diredp-hide-details-initially-flag nil))

(provide 'init-dired-plus)

;;; init-dired-plus.el ends here