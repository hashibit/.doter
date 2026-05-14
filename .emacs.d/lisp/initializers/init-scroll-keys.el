
(pixel-scroll-precision-mode 1)

;; scroll with cursor not move
(defun gcm-scroll-down () (interactive) (scroll-up 1))
(defun gcm-scroll-up () (interactive) (scroll-down 1))


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


(global-set-key [remap scroll-down-command] #'scroll-half-page-down)
(global-set-key [remap scroll-up-command] #'scroll-half-page-up)
(define-key global-map [(meta up)] #' (lambda () (interactive) (scroll-other-window-half-page-down)))
(define-key global-map [(meta down)] #' (lambda () (interactive) (scroll-other-window-half-page-up)))



(provide 'init-scroll-keys)
