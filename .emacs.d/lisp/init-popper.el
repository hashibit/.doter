;; -*- lexical-binding: t -*-
;;; init-popper.el --- Popper Configuration

;;; Commentary:
;;
;;  Popup window management
;;

;;; Code:

(require 'cl-lib)

(use-package popper
  :ensure t
  :demand t
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  (setq popper-reference-buffers
        '("\\*Messages\\*"
          "Output\\*$"
          "\\*Async Shell Command\\*"
          help-mode
          compilation-mode))
  ;; Match eshell, shell, term and/or vterm buffers
  (setq popper-reference-buffers
        (append popper-reference-buffers
                '("^\\*eshell.*\\*$" eshell-mode ;eshell as a popup
                  "^\\*shell.*\\*$"  shell-mode  ;shell as a popup
                  "^\\*term.*\\*$"   term-mode   ;term as a popup
                  flymake-diagnostics-buffer-mode
                  "^\\*eat.*\\*$"    eat-mode    ;eat as a popup
                  )))
  (popper-mode +1)
  (popper-echo-mode +1)
  :config
  (defun my-popper-maximum-height() (interactive) (setq popper-window-height (- (window-height) 2)))
  (defun my-popper-restore-height() (interactive) (setq popper-window-height 0.6))
  (my-popper-restore-height))







(defvar popper-saved-enhanced-config nil
  "保存 popper 打开前的增强窗口配置。")

(cl-defstruct popper-window-state
  config
  window-details)

(defun popper-collect-window-details ()
  "收集当前所有窗口的详细信息。"
  (mapcar (lambda (window)
            (list :window window
                  :buffer (window-buffer window)
                  :point (window-point window)
                  :window-start (window-start window)
                  :window-end (window-end window)))
          (window-list)))

(defun popper-save-enhanced-layout (&rest _args)
  "保存增强的窗口布局（包括光标和滚动位置）。"
  (setq popper-saved-enhanced-config
        (make-popper-window-state
         :config (current-window-configuration)
         :window-details (popper-collect-window-details))))

(defun popper-restore-enhanced-layout (&rest _args)
  "恢复增强的窗口布局。"
  (when popper-saved-enhanced-config
    ;; 先恢复窗口配置
    (set-window-configuration
     (popper-window-state-config popper-saved-enhanced-config))

    ;; 然后恢复详细位置信息
    (dolist (detail (popper-window-state-window-details popper-saved-enhanced-config))
      (let ((window (plist-get detail :window))
            (buffer (plist-get detail :buffer)))
        (when (and (window-live-p window)
                   (buffer-live-p buffer)
                   (eq (window-buffer window) buffer))
          (set-window-start window (plist-get detail :window-start) t)
          (set-window-point window (plist-get detail :point)))))

    (setq popper-saved-enhanced-config nil)))

;; 使用增强版 advice
;; 这个是在打开 popper 的时候。我们的 popper 在底部打开
(advice-add 'popper-select-popup-at-bottom :before #'popper-save-enhanced-layout)
;; 这是个 popper 在关闭的时候
(advice-add 'popper-close-latest :after #'popper-restore-enhanced-layout)



(provide 'init-popper)

;;; init-popper.el ends here
