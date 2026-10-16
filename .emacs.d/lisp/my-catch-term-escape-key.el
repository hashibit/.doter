;;; -*- lexical-binding: t -*-

;;;;;; catch ESC in terminal(-nw) ;;;;;;;;;;;;
(defvar personal/fast-keyseq-timeout 1)
(defun personal/-tty-ESC-filter (map)
  (if (and (equal (this-single-command-keys) [?\e])
        (sit-for (/ personal/fast-keyseq-timeout 1000.0)))
    [escape]
    map))
(defun personal/-lookup-key (map key)
  (lookup-key map (vector key)))
(defun personal/catch-tty-ESC ()
  "Setup key mappings of current terminal to turn a tty's ESC into `escape'."
  (when (memq (terminal-live-p (frame-terminal)) '(t pc))
    (let ((esc-binding (personal/-lookup-key input-decode-map ?\e)))
      ;; 避免重复包装（init 加载时与 tty-setup-hook 都会调用）
      (unless (and (eq (car-safe esc-binding) 'menu-item)
                   (memq #'personal/-tty-ESC-filter esc-binding))
        (keymap-set input-decode-map "ESC"
          `(menu-item "" ,esc-binding :filter personal/-tty-ESC-filter))))))
;; emacsclient -t 新建的 tty frame 也需要
(add-hook 'tty-setup-hook #'personal/catch-tty-ESC)
(personal/catch-tty-ESC)



(provide 'my-catch-term-escape-key)
