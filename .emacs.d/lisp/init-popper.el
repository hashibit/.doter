;; -*- lexical-binding: t -*-
;;; init-popper.el --- Popper Configuration

;;; Commentary:
;;
;;  Popup window management
;;

;;; Code:

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

(defstruct popper-window-state
  config
  window-details)

(defun popper-collect-window-details ()
  "收集当前所有窗口的详细信息。"
  (mapcar (lambda (window)
            (with-selected-window window
              (list :buffer (current-buffer)
                    :point (point)
                    :window-start (window-start)
                    :window-end (window-end))))
          (window-list)))

(defun popper-save-enhanced-layout (&rest args)
  "保存增强的窗口布局（包括光标和滚动位置）。"
  (setq popper-saved-enhanced-config
        (make-popper-window-state
         :config (current-window-configuration)
         :window-details (popper-collect-window-details)))
  (message "Popper: 增强窗口布局已保存"))

(defun popper-restore-enhanced-layout ()
  "恢复增强的窗口布局。"
  (when popper-saved-enhanced-config
    ;; 先恢复窗口配置
    (set-window-configuration
     (popper-window-state-config popper-saved-enhanced-config))

    ;; 然后恢复详细位置信息
    (let ((details (popper-window-state-window-details popper-saved-enhanced-config))
          (windows (window-list)))
      (cl-loop for window in windows
               for detail in details
               when detail do
               (with-selected-window window
                 (let ((buffer (plist-get detail :buffer))
                       (point (plist-get detail :point))
                       (start (plist-get detail :window-start)))
                   (when (and buffer (buffer-live-p buffer)
                              (eq (current-buffer) buffer))
                     (goto-char point)
                     (set-window-start window start))))))

    (setq popper-saved-enhanced-config nil)
    (message "Popper: 增强窗口布局已恢复")))

;; 使用增强版 advice
;; 这个是在打开 popper 的时候。我们的 popper 在底部打开
(advice-add 'popper-select-popup-at-bottom :before #'popper-save-enhanced-layout)
;; 这是个 popper 在关闭的时候
(advice-add 'popper-close-latest :after #'popper-restore-enhanced-layout)



(provide 'init-popper)

;;; init-popper.el ends here
