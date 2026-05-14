;; -*- lexical-binding: t -*-

(use-package expand-region
  :bind (("M-i" . 'er/expand-region)))

(advice-add 'er/expand-region :before (lambda (&rest r) (my-remove-all-highlight)))
(advice-add 'er/mark-inside-pairs :before (lambda (&rest r) (my-remove-all-highlight)))


(defun my-toggle-er/mark-defun (arg)
  (interactive "p")
  (if (use-region-p)
    (progn
      (jump-to-register 'a)
      (keyboard-quit))
    (point-to-register 'a)
    (er/mark-defun)))

(defun my-toggle-er/mark-inside-paren (arg)
  (interactive "p")
  (if (use-region-p)
    (progn
      (jump-to-register 'a)
      (keyboard-quit)
      )
    (point-to-register 'a)
    (cond
      ((er--point-inside-string-p) (er/mark-inside-quotes))
      ((er--point-inside-pairs-p) (er/mark-inside-pairs))
      )
    )
  )

(defun my-toggle-er/mark-outside-paren (arg)
  (interactive "p")
  (if (use-region-p)
    (progn
      (jump-to-register 'a)
      (keyboard-quit))
    (point-to-register 'a)
    (cond
      ((er--point-inside-string-p) (er/mark-outside-quotes))
      ((er--point-inside-pairs-p) (er/mark-outside-pairs))
      )
    )
  )



(provide 'init-expand-region)
