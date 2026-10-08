;;; -*- lexical-binding: t -*-
;;; 增强的 winner-mode 配置
;;; 同时保存和恢复窗口布局、光标位置和滚动位置

(require 'cl-lib)
(require 'ring)
(require 'winner)

;; 启用 winner-mode
(winner-mode 1)

;; 存储窗口详细信息的变量
(defvar enhanced-winner-window-details-ring (make-ring 200)
  "Ring to store detailed window information including point and scroll positions.")

(defvar enhanced-winner-current-index 0
  "Current index in the enhanced winner ring.")

(cl-defstruct enhanced-window-info
  buffer
  point
  window-start
  window-end)

(defun enhanced-winner--collect-window-details ()
  "收集当前所有窗口的详细信息。"
  (let ((details '()))
    (dolist (window (window-list))
      (with-selected-window window
        (push (make-enhanced-window-info
                :buffer (current-buffer)
                :point (point)
                :window-start (window-start)
                :window-end (window-end))
          details)))
    (nreverse details)))

(defun enhanced-winner--save-configuration ()
  "保存当前窗口配置和详细信息。"
  (let ((details (enhanced-winner--collect-window-details)))
    (ring-insert enhanced-winner-window-details-ring details)
    (setq enhanced-winner-current-index 0)))

(defun enhanced-winner--restore-window-details (details)
  "恢复窗口的详细位置信息。"
  (let ((windows (window-list))
         (detail-index 0))
    (dolist (window windows)
      (when (< detail-index (length details))
        (let ((detail (nth detail-index details)))
          (with-selected-window window
            ;; 检查缓冲区是否匹配
            (when (and detail
                    (buffer-live-p (enhanced-window-info-buffer detail))
                    (eq (current-buffer) (enhanced-window-info-buffer detail)))
              ;; 恢复光标位置
              (goto-char (enhanced-window-info-point detail))
              ;; 恢复滚动位置
              (set-window-start window (enhanced-window-info-window-start detail)))))
        (setq detail-index (1+ detail-index))))))

(defun enhanced-winner-undo ()
  "增强版的 winner-undo，同时恢复光标和滚动位置。"
  (interactive)
  ;; 在第一次调用时保存当前状态
  (when (not (eq last-command 'enhanced-winner-undo))
    (enhanced-winner--save-configuration))

  ;; 调用原始的 winner-undo
  (winner-undo)

  ;; 恢复详细的窗口信息
  (let ((target-index (1+ enhanced-winner-current-index)))
    (when (< target-index (ring-length enhanced-winner-window-details-ring))
      (let ((details (ring-ref enhanced-winner-window-details-ring target-index)))
        (enhanced-winner--restore-window-details details)
        (setq enhanced-winner-current-index target-index)))))

(defun enhanced-winner-redo ()
  "增强版的 winner-redo，同时恢复光标和滚动位置。"
  (interactive)
  ;; 调用原始的 winner-redo
  (winner-redo)

  ;; 恢复详细的窗口信息
  (when (> enhanced-winner-current-index 0)
    (setq enhanced-winner-current-index (1- enhanced-winner-current-index))
    (let ((details (ring-ref enhanced-winner-window-details-ring enhanced-winner-current-index)))
      (enhanced-winner--restore-window-details details))))

;; 自动保存钩子
(defun enhanced-winner--auto-save ()
  "自动保存窗口配置的钩子函数。"
  (unless (or (memq this-command '(enhanced-winner-undo enhanced-winner-redo))
            (minibufferp))
    (enhanced-winner--save-configuration)))

;; 在窗口配置改变时自动保存
(add-hook 'window-configuration-change-hook #'enhanced-winner--auto-save)

;; 重新绑定快捷键
(keymap-set winner-mode-map "C-c <left>" #'enhanced-winner-undo)
(keymap-set winner-mode-map "C-c <right>" #'enhanced-winner-redo)

;; 也可以绑定到其他键
(keymap-global-set "C-x 4 u" #'enhanced-winner-undo)
(keymap-global-set "C-x 4 r" #'enhanced-winner-redo)

;; 显示当前状态的辅助函数
(defun enhanced-winner-show-info ()
  "显示增强 winner 模式的当前状态信息。"
  (interactive)
  (message "Enhanced Winner: %d/%d configurations stored"
    (1+ enhanced-winner-current-index)
    (ring-length enhanced-winner-window-details-ring)))

;; 清理历史的函数
(defun enhanced-winner-clear-history ()
  "清除增强 winner 模式的历史记录。"
  (interactive)
  (setq enhanced-winner-window-details-ring (make-ring 200))
  (setq enhanced-winner-current-index 0)
  (message "Enhanced Winner history cleared"))

;; 可选：配置保存更频繁的触发条件
(defvar enhanced-winner-save-timer nil
  "Timer for periodic saving of window configurations.")

(defun enhanced-winner-start-periodic-save ()
  "启动定期保存窗口配置。"
  (interactive)
  (when enhanced-winner-save-timer
    (cancel-timer enhanced-winner-save-timer))
  (setq enhanced-winner-save-timer
    (run-with-idle-timer 2 t #'enhanced-winner--auto-save)))

(defun enhanced-winner-stop-periodic-save ()
  "停止定期保存。"
  (interactive)
  (when enhanced-winner-save-timer
    (cancel-timer enhanced-winner-save-timer)
    (setq enhanced-winner-save-timer nil)))

;; 可选：启用定期保存（每2秒空闲时保存一次）
;; (enhanced-winner-start-periodic-save)

;; 提供一个手动保存当前配置的命令
(defun enhanced-winner-save-now ()
  "手动保存当前窗口配置。"
  (interactive)
  (enhanced-winner--save-configuration)
  (message "Current window configuration saved"))

(keymap-global-set "C-x 4 s" #'enhanced-winner-save-now)

(provide 'enhanced-winner-mode)
