;; -*- lexical-binding: t -*-
;;; init-scroll-keys.el --- Scrolling configuration

;;; Code:

(pixel-scroll-precision-mode 1)

;; scroll with cursor not move
(defalias 'gcm-scroll-down #'scroll-up-line)
(defalias 'gcm-scroll-up #'scroll-down-line)


(setq
 scroll-margin 0
 scroll-conservatively 99
 scroll-up-aggressively 0.01
 scroll-down-aggressively 0.01
 scroll-preserve-screen-position nil
 auto-window-vscroll nil)

(defun my-scroll-full-page-down ()
  "Scroll down most of a page."
  (interactive)
  (scroll-down (* (/ (window-body-height) 5) 4)))

(defun my-scroll-full-page-up ()
  "Scroll up most of a page."
  (interactive)
  (scroll-up (* (/ (window-body-height) 5) 4)))

;; (defun my-scroll-half-page-down ()
;;   (interactive)
;;   (scroll-down (/ (window-body-height) 2)))
;;
;; (defun my-scroll-half-page-up ()
;;   (interactive)
;;   (scroll-up (/ (window-body-height) 2)))


(defun my-scroll-half-page-down ()
  "Scroll down about half a page."
  (interactive)
  (scroll-down (* (/ (window-body-height) 20) 9)))

(defun my-scroll-half-page-up ()
  "Scroll up about half a page."
  (interactive)
  (scroll-up (* (/ (window-body-height) 20) 9)))


(defun my-scroll-other-window-half-page-up ()
  "Scroll the other window up half a page."
  (interactive)
  (scroll-other-window (/ (window-body-height) 2)))

(defun my-scroll-other-window-half-page-down ()
  "Scroll the other window down half a page."
  (interactive)
  (scroll-other-window (- 0 (/ (window-body-height) 2))))


(keymap-global-set "<remap> <scroll-down-command>" #'my-scroll-half-page-down)
(keymap-global-set "<remap> <scroll-up-command>" #'my-scroll-half-page-up)
(keymap-global-set "M-<up>" #'my-scroll-other-window-half-page-down)
(keymap-global-set "M-<down>" #'my-scroll-other-window-half-page-up)



;; Old names, so M-x with the old name still works.
(define-obsolete-function-alias 'scroll-full-page-down #'my-scroll-full-page-down "2026-10-27")
(define-obsolete-function-alias 'scroll-full-page-up #'my-scroll-full-page-up "2026-10-27")
(define-obsolete-function-alias 'scroll-half-page-down #'my-scroll-half-page-down "2026-10-27")
(define-obsolete-function-alias 'scroll-half-page-up #'my-scroll-half-page-up "2026-10-27")
(define-obsolete-function-alias 'scroll-other-window-half-page-down #'my-scroll-other-window-half-page-down "2026-10-27")
(define-obsolete-function-alias 'scroll-other-window-half-page-up #'my-scroll-other-window-half-page-up "2026-10-27")

(provide 'init-scroll-keys)

;;; init-scroll-keys.el ends here
