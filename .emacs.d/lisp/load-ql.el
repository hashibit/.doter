;; -*- lexical-binding: t -*-
(require 'lispy)
(require 'le-lisp)

(lispy--eval-lisp "(load \"~/quicklisp/setup\")")
(lispy--eval-lisp "(ql:quickload 'drakma)")


(provide 'load-ql)
