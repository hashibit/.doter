

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
  :config
  (setq eldoc-box-clear-with-C-g t)
  (set-face-attribute 'eldoc-box-body nil :background "#000000")
  (setq eldoc-box-max-pixel-width 1000)
  ;; Add extra height to childframe to prevent content truncation
  (add-hook 'eldoc-box-frame-hook
    (lambda (_main-frame)
      (let ((frame (selected-frame)))
        (set-frame-size frame
          (+ (frame-pixel-width frame) (* 2 (frame-char-width frame)))
          (+ (frame-pixel-height frame) (frame-char-height frame))
          t))))
  :commands (eldoc-box-help-at-point))


;; show eldoc for our move command, so we can display eldoc info such as flymake errors in minibuffer
(with-eval-after-load 'eldoc
    (eldoc-add-command 'my-forward-char-no-cross-line)
    (eldoc-add-command 'my-backward-char-no-cross-line)
    (eldoc-add-command 'my-forward-to-word)
    (eldoc-add-command 'my-next-line)
    (eldoc-add-command 'my-previous-line))


(provide 'init-eldoc)
