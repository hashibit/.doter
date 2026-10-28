;; -*- lexical-binding: t -*-
;;; init-selected.el --- Selected-mode configuration

;;; Code:

(defvar my-visual-line-selection)
(declare-function mwim-end-of-code-or-line "mwim")
(declare-function mwim-beginning-of-code-or-line "mwim")

(defun my-kill-region-and-insert-d-in-selected()
  "Kill the region and insert d (unless in god-mode)."
  (interactive)
  (kill-region (region-beginning) (region-end))
  (when my-visual-line-selection (delete-char 1))
  (unless (bound-and-true-p god-local-mode)
    (insert-char ?d)))

(defun my-kill-region-and-insert-s-in-selected()
  "Kill the region and insert s (unless in god-mode)."
  (interactive)
  (kill-region (region-beginning) (region-end))
  (when my-visual-line-selection (delete-char 1))
  (unless (bound-and-true-p god-local-mode)
    (insert-char ?s))
  ;; force insert mode
  (god-local-mode -1))

(defun my-select-to-eol()
  "Extend the region to the end of code on the line."
  (interactive)
  (mwim-end-of-code-or-line)
  ;; (exchange-point-and-mark)
  )

(defun my-select-to-bol()
  "Extend the region to the start of code on the line."
  (interactive)
  (mwim-beginning-of-code-or-line)
  ;; (exchange-point-and-mark)
  )

(use-package selected
  :ensure t
  :commands selected-minor-mode
  :bind ((:map
          selected-keymap
          ("C-c i" . clang-format-region)
          ("C-c f" . clang-format-buffer)
          ("(" . my-wrap-region-with-parens)
          ("[" . my-wrap-region-with-brackets)
          ("{" . my-wrap-region-with-braces)
          ("M-'" . my-wrap-region-with-single-quotes)
          ("\"" . my-wrap-region-with-double-quotes)
          ("_" . my-wrap-region-with-underscores)
          ("`" . my-wrap-region-with-back-quotes)
          ("d" . my-kill-region-and-insert-d-in-selected)
          ("s" . my-kill-region-and-insert-s-in-selected)
          ("C-d" . kill-region)
          ("e" . my-select-to-eol)
          ("a" . my-select-to-bol))))

(selected-global-mode 1)


(defvar selected-active-timer nil)
(defvar unselected-active-timer nil)

(defun my-selected--disable-highlights ()
  (when (region-active-p)
    (remove-all-highlight)
    (my-disable-symbol-overlay-highlight)
    (my-disable-paren-highlight)
    (my-disable-eglot-highlight)))

(defun my-selected--enable-highlights ()
  (unless (region-active-p)
    (my-enable-eglot-highlight)
    (my-enable-symbol-overlay-highlight)
    (my-enable-paren-highlight)))

(defun my-toggle-selected-keybinding ()
  "add special keybindings for visual selected mode"
  (interactive)
  ;; (message "toggle selected keybinding")
  (if (bound-and-true-p selected-region-active-mode)
      ;; only non-special buffer and vterm buffer need this timer.
      (when (my-god-this-is-normal-editor-buffer (buffer-name))
        (when (timerp selected-active-timer) (cancel-timer selected-active-timer))
        (setq selected-active-timer
              (run-with-timer 0.05 nil #'my-selected--disable-highlights)))
    (when (timerp unselected-active-timer) (cancel-timer unselected-active-timer))
    (setq unselected-active-timer
          (run-with-timer 0.05 nil #'my-selected--enable-highlights))))

(add-hook 'selected-region-active-mode-hook #'my-toggle-selected-keybinding)


(provide 'init-selected)

;;; init-selected.el ends here
