

;; for my-elisp-eldoc-var-docstring-with-value
;; (require 'my-utils)

(use-package eldoc
  :config
  (setq eldoc-echo-area-use-multiline-p 1)
  (setq eldoc-idle-delay 0.2)
  ;; show more doc in elisp mode
  (add-hook
    'emacs-lisp-mode-hook
    '(lambda () (add-to-list 'eldoc-documentation-functions 'elisp-eldoc-var-docstring-with-value)))
  (add-hook
    'lisp-mode-hook
    '(lambda () (add-to-list 'eldoc-documentation-functions 'elisp-eldoc-var-docstring-with-value))))

(use-package eldoc-box
  :config (setq eldoc-box-clear-with-C-g t)
  :commands (eldoc-box-help-at-point))


;; show eldoc for our move command, so we can display eldoc info such as flymake errors in minibuffer
(with-eval-after-load 'eldoc
    (eldoc-add-command 'my-forward-char-no-cross-line)
    (eldoc-add-command 'my-backward-char-no-cross-line)
    (eldoc-add-command 'my-forward-to-word)
    (eldoc-add-command 'my-next-line)
    (eldoc-add-command 'my-previous-line))


(provide 'init-eldoc)
