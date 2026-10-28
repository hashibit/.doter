;; -*- lexical-binding: t -*-
;;; init-avy.el --- Avy configuration

;;; Code:

(require 'avy)
(setq avy-keys (list ?a ?s ?d ?f ?g ?w ?e ?v ?m ?n ?i ?o ?h ?j ?k ?l ?\;))
(setq avy-background t)
(add-to-list 'avy-ignored-modes 'treemacs-mode)


;; avy 开始前关闭 hl-line，结束后恢复原来的状态
(defvar my-avy--hl-line-buffer nil
  "Buffer whose `hl-line-mode' was turned off when avy started.")

(defun my-avy-start (&rest _)
  (my-disable-code-intelligence)
  (when (bound-and-true-p hl-line-mode)
    (setq my-avy--hl-line-buffer (current-buffer))
    (hl-line-mode 0)))

(defun my-avy-end (&rest _)
  (my-enable-code-intelligence)
  (when (buffer-live-p my-avy--hl-line-buffer)
    (with-current-buffer my-avy--hl-line-buffer
      (hl-line-mode 1)))
  (setq my-avy--hl-line-buffer nil))

(advice-add 'avy-goto-word-0 :before #'my-avy-start)
;; avy aborted
(advice-add 'avy-handler-default :before #'my-avy-end)
;; avy success
(advice-add 'avy-action-goto :before #'my-avy-end)

(provide 'init-avy)

;;; init-avy.el ends here
