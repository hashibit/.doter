;; -*- lexical-binding: t -*-
;;; init-blink-search.el --- Blink-search configuration

;;; Commentary:
;;
;;  Not loaded by init.el. Needs blink-search in lisp/blink-search.
;;

;;; Code:

(defvar blink-search-history-path)
(defvar blink-search-db-path)

(let ((dir (locate-user-emacs-file "lisp/blink-search")))
  (when (and (file-directory-p dir) (not (directory-empty-p dir)))
    (add-to-list 'load-path dir)
    (setq blink-search-history-path
          (locate-user-emacs-file ".local/blink-search/history.txt"))
    (setq blink-search-db-path
          (locate-user-emacs-file ".local/blink-search/blink-search.db"))
    (require 'blink-search)))

(provide 'init-blink-search)

;;; init-blink-search.el ends here
