(require 'smartparens-config)
(require 'sp-sublimetext-like)

(smartparens-global-mode 1)

(defun indent-between-pair (&rest _ignored)
  (indent-according-to-mode)
  (forward-line -1)
  (indent-according-to-mode))

(with-eval-after-load 'smartparens
  ;; but still should init, so that some variables are set, such as sp-pair-list
  (sp-local-pair 'prog-mode "{" nil :post-handlers '((indent-between-pair "RET")))
  (sp-local-pair 'prog-mode "[" nil :post-handlers '((indent-between-pair "RET")))
  (sp-local-pair 'prog-mode "(" nil :post-handlers '((indent-between-pair "RET")))
  (setq sp-highlight-pair-overlay nil))


;;
;; borrow from https://github.com/lujun9972/emacs-document/blob/master/emacs-common/Smartparens%E7%94%A8%E6%B3%95%E8%AF%A6%E8%A7%A3.org#key
;;
(defmacro def-region-pairs (pairs)
  "Define functions for pairing. PAIRS is an alist of (NAME . STRING)
conses, where NAME is the function name that will be created and
STRING is a single-character string that marks the opening character.

  (def-pairs ((paren . \"(\")
              (bracket . \"[\"))

defines the functions WRAP-WITH-PAREN and WRAP-WITH-BRACKET,
respectively."
  `(progn
     ,@ (cl-loop
          for (key . val) in pairs collect
          `(defun
             ,(read (concat "my-wrap-region-with-" (prin1-to-string key) "s"))
             (start stop)
             (interactive "r")
             (sp-wrap-with-pair ,val)

             (goto-char (+ 1 start))
             (push-mark (+ 1 stop))
             ;; (setq deactivate-mark nil)
             ;; i prefer deactivate mark
             (setq deactivate-mark t)
             ))))

(def-region-pairs ((paren . "(")
                    (bracket . "[")
                    (brace . "{")
                    (single-quote . "'")
                    (double-quote . "\"")
                    (back-quote . "`")))

(bind-keys :map smartparens-mode-map
  ("C-c (" . my-wrap-region-with-parens)
  ("C-c [" . my-wrap-region-with-brackets)
  ("C-c {" . my-wrap-region-with-braces)
  ("C-c C-'" . my-wrap-region-with-single-quotes)
  ("C-c \"" . my-wrap-region-with-double-quotes)
  ("C-c _" . my-wrap-region-with-underscores)
  ("C-c `" . my-wrap-region-with-back-quotes))



(require 'emacs-surround)
(add-to-list 'emacs-surround-alist '("}" . ("{ " . " }")))
(add-to-list 'emacs-surround-alist '(")" . ("( " . " )")))
(add-to-list 'emacs-surround-alist '("]" . ("[ " . " ]")))
;; (global-set-key (kbd "C-c p") 'emacs-surround)


(provide 'init-smartparens)
