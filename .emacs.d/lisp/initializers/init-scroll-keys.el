;;; -*- lexical-binding: t -*-

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

(defun scroll-full-page-down ()
  (interactive)
  (scroll-down (* (/ (window-body-height) 5) 4)))

(defun scroll-full-page-up ()
  (interactive)
  (scroll-up (* (/ (window-body-height) 5) 4)))

;; (defun scroll-half-page-down ()
;;   (interactive)
;;   (scroll-down (/ (window-body-height) 2)))
;;
;; (defun scroll-half-page-up ()
;;   (interactive)
;;   (scroll-up (/ (window-body-height) 2)))


(defun scroll-half-page-down ()
  (interactive)
  (scroll-down (* (/ (window-body-height) 20) 9)))

(defun scroll-half-page-up ()
  (interactive)
  (scroll-up (* (/ (window-body-height) 20) 9)))


(defun scroll-other-window-half-page-up ()
  (interactive)
  (scroll-other-window (/ (window-body-height) 2)))

(defun scroll-other-window-half-page-down ()
  (interactive)
  (scroll-other-window (- 0 (/ (window-body-height) 2))))


(keymap-global-set "<remap> <scroll-down-command>" #'scroll-half-page-down)
(keymap-global-set "<remap> <scroll-up-command>" #'scroll-half-page-up)
(keymap-global-set "M-<up>" #'scroll-other-window-half-page-down)
(keymap-global-set "M-<down>" #'scroll-other-window-half-page-up)



(provide 'init-scroll-keys)
