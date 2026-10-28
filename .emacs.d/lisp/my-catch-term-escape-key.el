;; -*- lexical-binding: t -*-
;;; my-catch-term-escape-key.el --- Turn a terminal ESC into the escape key

;;;;;; catch ESC in terminal(-nw) ;;;;;;;;;;;;

;;; Code:

(defvar my-term-esc-timeout 1)
(defun my-term-esc--tty-filter (map)
  (if (and (equal (this-single-command-keys) [?\e])
           (sit-for (/ my-term-esc-timeout 1000.0)))
      [escape]
    map))
(defun my-term-esc--lookup-key (map key)
  (lookup-key map (vector key)))
(defun my-term-esc-catch-tty ()
  "Setup key mappings of current terminal to turn a tty's ESC into `escape'."
  (when (memq (terminal-live-p (frame-terminal)) '(t pc))
    (let ((esc-binding (my-term-esc--lookup-key input-decode-map ?\e)))
      ;; 避免重复包装（init 加载时与 tty-setup-hook 都会调用）
      (unless (and (eq (car-safe esc-binding) 'menu-item)
                   (memq #'my-term-esc--tty-filter esc-binding))
        (keymap-set input-decode-map "ESC"
                    `(menu-item "" ,esc-binding :filter my-term-esc--tty-filter))))))
;; emacsclient -t 新建的 tty frame 也需要
(add-hook 'tty-setup-hook #'my-term-esc-catch-tty)
(my-term-esc-catch-tty)



(provide 'my-catch-term-escape-key)

;;; my-catch-term-escape-key.el ends here
