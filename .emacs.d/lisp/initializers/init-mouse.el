;;; -*- lexical-binding: t -*-


;; enable mouse click in terminal
(unless (display-graphic-p)
  (xterm-mouse-mode 1))

(defun my-mouse-scroll-down-2 ()
  (interactive)
  (scroll-down 2))

(defun my-mouse-scroll-up-2 ()
  (interactive)
  (scroll-up 2))

(keymap-global-set "<mouse-4>" #'my-mouse-scroll-down-2)
(keymap-global-set "<mouse-5>" #'my-mouse-scroll-up-2)


(defalias 'my-mouse-find-definition-at-mouse #'xref-find-definitions-at-mouse)




(defvar my/xref-gesture-last-time 0
  "Timestamp of the last successful xref gesture execution.")

(defvar my/xref-gesture-delay 0.5
  "Minimum time in seconds between gesture triggers (Rate Limit).")

(defun my/xref-go-back-throttled ()
  "Throttled version of `xref-go-back` for touch gestures.
Ignores calls if they happen too frequently."
  (interactive)
  (let ((now (float-time)))
    (if (> (- now my/xref-gesture-last-time) my/xref-gesture-delay)
        ;; 时间间隔足够，执行命令并更新时间
        (progn
          (setq my/xref-gesture-last-time now)
          (call-interactively #'xref-go-back))
      ;; 时间间隔太短，忽略本次触发 (可选：加个 message 调试)
      ;; (message "Gesture ignored (rate limit)")
      nil)))

(defun my/xref-go-forward-throttled ()
  "Throttled version of `xref-go-forward` for touch gestures.
Ignores calls if they happen too frequently."
  (interactive)
  (let ((now (float-time)))
    (if (> (- now my/xref-gesture-last-time) my/xref-gesture-delay)
        ;; 时间间隔足够，执行命令并更新时间
        (progn
          (setq my/xref-gesture-last-time now)
          (call-interactively #'xref-go-forward))
      ;; 时间间隔太短，忽略本次触发 (可选：加个 message 调试)
      ;; (message "Gesture ignored (rate limit)")
      nil)))




(keymap-global-set "s-<mouse-1>" #'my-mouse-find-definition-at-mouse)

;; 绑定按键
(keymap-global-set "s-<mouse-3>"           #'my/xref-go-back-throttled)
(keymap-global-set "s-<triple-wheel-down>" #'my/xref-go-back-throttled)
(keymap-global-set "s-<triple-wheel-up>"   #'my/xref-go-forward-throttled)



(keymap-global-set "M-<mouse-1>" #'my-mouse-find-definition-at-mouse)
(keymap-global-unset "M-<down-mouse-1>")

(keymap-global-set "M-<mouse-3>" #'xref-go-back)
(keymap-global-set "C-<mouse-3>" #'xref-find-references-at-mouse)
(keymap-global-unset "C-<down-mouse-3>")
(keymap-global-unset "M-<down-mouse-3>")



;;;   ;;; swipe to go backward and forward
;;;   ;;;
;;;   (defun my-start-cold-down-wheel()
;;;     (my-unbind-swipe-actions)
;;;     (run-with-timer 1 nil #'(lambda()
;;;                                 (my-bind-swipe-actions))))
;;;
;;;   (defun my-swipe-backward-with-cold-down ()
;;;     (interactive)
;;;       (xref-go-back)
;;;       (recenter)
;;;       (my-start-cold-down-wheel))
;;;
;;;   (defun my-swipe-forward-with-cold-down ()
;;;     (interactive)
;;;       (xref-go-forward)
;;;       (recenter)
;;;       (my-start-cold-down-wheel))
;;;
;;;   (defun my-unbind-swipe-actions ()
;;;     (global-unset-key [wheel-left])
;;;     (global-unset-key [wheel-right])
;;;     )
;;;
;;;   (defun my-bind-swipe-actions ()
;;;     (define-key global-map (kbd "<wheel-left>") 'my-swipe-backward-with-cold-down)
;;;     (define-key global-map (kbd "<wheel-right>") 'my-swipe-forward-with-cold-down)
;;;     )
;;;
;;;   (when (my-system-type-is-darwin)
;;;     (my-bind-swipe-actions)
;;;   )


;;; right click to open context-menu. disable mouse-3 to disable region behavior, which is annoying!
;;;
(keymap-global-unset "<mouse-3>")
(context-menu-mode 1)

(provide 'init-mouse)
