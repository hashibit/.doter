;; -*- lexical-binding: t -*-
;;; init-lang-scala.el --- Scala Language Configuration

;;; Commentary:
;;
;;  Scala programming language support
;;

;;; Code:

(use-package scala-mode
  :ensure t
  :interpreter ("scala" . scala-mode))

(provide 'init-lang-scala)

;;; init-lang-scala.el ends here