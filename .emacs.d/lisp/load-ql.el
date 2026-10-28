;; -*- lexical-binding: t -*-
;;; load-ql.el --- Load lispy's Common Lisp support

;;; Code:

(require 'lispy)
(require 'le-lisp)

(lispy--eval-lisp "(load \"~/quicklisp/setup\")")
(lispy--eval-lisp "(ql:quickload 'drakma)")


(provide 'load-ql)

;;; load-ql.el ends here
