;; -*- lexical-binding: t -*-
;;; my-highlight-current-line.el --- Highlight the current line on demand

;;; Code:

(require 'seq)

(defun my-find-overlays-specifying (prop pos)
  (seq-filter (lambda (ov) (overlay-get ov prop)) (overlays-at pos)))

(defun my-highlight-line ()
  "Highlight the current line."
  (interactive)
  (let ((overlay-highlight (make-overlay (line-beginning-position) (+ 1 (line-end-position)))))
    (overlay-put overlay-highlight 'face '(:inverse-video t))
    ;; (overlay-put overlay-highlight 'face '(:inherit hl-line))
    ;; (overlay-put overlay-highlight 'face '(:background "#1b5aa1"))
    (overlay-put overlay-highlight 'my-marker-name-for-line-highlight-overlay t)))

(defun my-dehighlight-current-line ()
  "Remove the highlight from the current line."
  (interactive)
  (remove-overlays (line-beginning-position)
                   (+ 1 (line-end-position)) 'my-marker-name-for-line-highlight-overlay t))

(defun my-highlight-or-dehighlight-line ()
  "Toggle the highlight of the current line."
  (interactive)
  (if (my-find-overlays-specifying 'my-marker-name-for-line-highlight-overlay (line-beginning-position))
      (my-dehighlight-current-line)
    (my-highlight-line)))

(defun my-remove-all-line-highlights ()
  "Remove all line highlights in the buffer."
  (interactive)
  (remove-overlays (point-min) (point-max) 'my-marker-name-for-line-highlight-overlay t)
  ;; this truly removes all, not restricted by the name
  ;; (remove-overlays (point-min) (point-max))
  )




(keymap-global-set "<f8>" #'my-highlight-or-dehighlight-line)

(keymap-global-set "<f9>" #'my-remove-all-line-highlights)


;; (setq unhighlight-timer nil)
;; (defun my-highlight-line-momentarily (&optional ARG PRED)
;;   (interactive)
;;   ;; (recenter)
;;   (xref-pulse-momentarily)
;;   ;; (my-remove-all-line-highlights)
;;   ;; (my-disable-eglot-highlight)
;;   ;; (my-highlight-line)
;;   ;; (when (bound-and-true-p unhighlight-timer)
;;   ;;     (cancel-timer unhighlight-timer))
;;   ;; (setq unhighlight-timer (run-with-timer 0.3 nil #'(lambda() (my-remove-all-line-highlights) (my-enable-eglot-highlight))))
;; )


;; Old names, so M-x with the old name still works.
(define-obsolete-function-alias 'dehighlight-current-line #'my-dehighlight-current-line "2026-10-27")
(define-obsolete-function-alias 'highlight-current-line #'my-highlight-line "2026-10-27")
(define-obsolete-function-alias 'highlight-or-dehighlight-line #'my-highlight-or-dehighlight-line "2026-10-27")
(define-obsolete-function-alias 'remove-all-highlight #'my-remove-all-line-highlights "2026-10-27")

(provide 'my-highlight-current-line)

;;; my-highlight-current-line.el ends here
