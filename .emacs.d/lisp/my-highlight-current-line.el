;;; -*- lexical-binding: t -*-
(require 'seq)

(defun find-overlays-specifying (prop pos)
  (seq-filter (lambda (ov) (overlay-get ov prop)) (overlays-at pos)))

(defun highlight-current-line ()
  (interactive)
  (let ((overlay-highlight (make-overlay (line-beginning-position) (+ 1 (line-end-position)))))
    (overlay-put overlay-highlight 'face '(:inverse-video t))
    ;; (overlay-put overlay-highlight 'face '(:inherit hl-line))
    ;; (overlay-put overlay-highlight 'face '(:background "#1b5aa1"))
    (overlay-put overlay-highlight 'my-marker-name-for-line-highlight-overlay t)))

(defun dehighlight-current-line ()
  (interactive)
  (remove-overlays (line-beginning-position)
                   (+ 1 (line-end-position)) 'my-marker-name-for-line-highlight-overlay t))

(defun highlight-or-dehighlight-line ()
  (interactive)
  (if (find-overlays-specifying 'my-marker-name-for-line-highlight-overlay (line-beginning-position))
      (dehighlight-current-line)
    (highlight-current-line)))

(defun remove-all-highlight ()
  (interactive)
  (remove-overlays (point-min) (point-max) 'my-marker-name-for-line-highlight-overlay t)
  ;; this truly removes all, not restricted by the name
  ;; (remove-overlays (point-min) (point-max))
  )




(keymap-global-set "<f8>" #'highlight-or-dehighlight-line)

(keymap-global-set "<f9>" #'remove-all-highlight)


;; (setq unhighlight-timer nil)
;; (defun my-highlight-line-momentarily (&optional ARG PRED)
;;   (interactive)
;;   ;; (recenter)
;;   (xref-pulse-momentarily)
;;   ;; (remove-all-highlight)
;;   ;; (my-disable-eglot-highlight)
;;   ;; (highlight-current-line)
;;   ;; (when (bound-and-true-p unhighlight-timer)
;;   ;;     (cancel-timer unhighlight-timer))
;;   ;; (setq unhighlight-timer (run-with-timer 0.3 nil #'(lambda() (remove-all-highlight) (my-enable-eglot-highlight))))
;; )


(provide 'my-highlight-current-line)
