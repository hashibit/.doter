;; -*- lexical-binding: t -*-
;;; init-eat.el --- Eat Terminal Configuration

;;; Commentary:
;;
;;  Terminal emulator configuration (replaces init-vterm.el)
;;

;;; Code:

(use-package eat
  :ensure t
  :commands eat
  :config

  (defun my-eat-copy-region (&optional arg)
    (interactive "p")
    (if (use-region-p)
        (kill-ring-save (region-beginning) (region-end))
      (save-excursion
        (copy-region-as-kill (line-beginning-position) (line-end-position)))))

  (defun my-eat-send-ctrl-c ()
    (interactive)
    (eat-self-input 1 ?\C-c))

  (setq eat-kill-buffer-on-exit t)
  (setq eat-scroll-to-bottom-on-output nil)

  (add-to-list 'display-buffer-alist
    '("^\\*eat" (display-buffer-same-window)))

  ;; Kill window when buffer is killed
  (add-hook 'eat-mode-hook
    (lambda ()
      (add-hook 'kill-buffer-hook
        (lambda ()
          (let ((window (get-buffer-window (current-buffer))))
            (when (and window (not (one-window-p)))
              (delete-window window))))
        nil t)))

  ;; Legendary buffer management: eat/claude buffers are always legendary
  (defun my-toggle-legendary-buffer-for-eat (&optional arg)
    (when (derived-mode-p 'eat-mode)
      (my-add-to-legendary-buffers '("*eat" "*claude"))
      (refresh-current-mode)))

  (add-hook 'eat-mode-hook #'my-toggle-legendary-buffer-for-eat)
  (add-hook 'window-buffer-change-functions #'my-toggle-legendary-buffer-for-eat)

  ;; Semi-char mode keybindings
  (setq eat-enable-yank-to-terminal t)
  (define-key eat-semi-char-mode-map (kbd "M->") #'end-of-buffer)
  (define-key eat-semi-char-mode-map (kbd "M-<") #'beginning-of-buffer)
  (define-key eat-semi-char-mode-map (kbd "M-i") #'er/expand-region)
  (define-key eat-semi-char-mode-map (kbd "M-h") #'windmove-left)
  (define-key eat-semi-char-mode-map (kbd "M-l") #'windmove-right)
  (define-key eat-semi-char-mode-map (kbd "C-s-c") #'my-eat-send-ctrl-c)
  (keymap-unset eat-semi-char-mode-map "M-`")
  (keymap-unset eat-semi-char-mode-map "M-:")

  ;; Return to bottom when switching back from emacs-mode to semi-char-mode
  (advice-add 'eat-switch-to-semi-char-mode :after
    (lambda (&rest _)
      (goto-char (point-max))))

  ;; Font/display setup for Claude Code flickering fix
  (defun diego--eat-font-setup ()
    (let ((tbl (or buffer-display-table (setq buffer-display-table (make-display-table)))))
      (dolist (pair '((#x273B . ?*) (#x273D . ?*) (#x2722 . ?+) (#x2736 . ?+) (#x2733 . ?*)))
        (aset tbl (car pair) (vector (cdr pair))))))

  (add-hook 'eat-mode-hook #'diego--eat-font-setup)
  (add-hook 'eat-mode-hook (lambda () (face-remap-add-relative 'nobreak-space :underline nil)))

  )


(provide 'init-eat)

;;; init-eat.el ends here
