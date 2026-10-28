;; -*- lexical-binding: t -*-
;;; my-isearch-highlight-all.el --- Safe isearch全局高亮

;;; Code:

(defvar my-isearch-all-overlays nil
  "存储所有 isearch 高亮的 overlays.")

(defvar my-isearch-last-string ""
  "上次高亮的搜索字符串，用于避免重复计算.")

(defvar my-isearch-highlight-timer nil
  "用于延迟高亮的定时器.")

(defun my-remove-all-isearch-overlays ()
  "移除所有 isearch 高亮 overlays."
  (dolist (ov my-isearch-all-overlays)
    (when (overlay-buffer ov)
      (delete-overlay ov)))
  (setq my-isearch-all-overlays nil))

(defun my-highlight-all-matches-delayed ()
  "延迟高亮所有匹配，避免频繁调用."
  (when my-isearch-highlight-timer
    (cancel-timer my-isearch-highlight-timer))

  (setq my-isearch-highlight-timer
        (run-with-idle-timer 0.3 nil #'my-highlight-all-matches-now)))

(defun my-highlight-all-matches-now ()
  "立即高亮所有匹配."
  (when (and isearch-mode
             (not (equal isearch-string my-isearch-last-string)))
    ;; 清除旧的高亮
    (my-remove-all-isearch-overlays)
    (setq my-isearch-last-string isearch-string)

    (when (> (length isearch-string) 2)  ; 至少3个字符才高亮
      (let ((case-fold-search isearch-case-fold-search)
            (pattern (if isearch-regexp
                         isearch-string
                       (regexp-quote isearch-string)))
            (max-matches 500)  ; 限制最大匹配数，避免卡死
            (match-count 0))

        (save-excursion
          (save-restriction
            (widen)  ; 确保搜索整个 buffer
            (goto-char (point-min))

            ;; 安全的搜索循环
            (condition-case nil
                (while (and (< match-count max-matches)
                            (not (eobp))
                            (re-search-forward pattern nil t))
                  (let ((beg (match-beginning 0))
                        (end (match-end 0)))
                    (if (= end beg)
                        ;; 避免零长度匹配导致的无限循环
                        (unless (eobp) (forward-char 1))
                      (let ((ov (make-overlay beg end)))
                        (overlay-put ov 'face 'lazy-highlight)
                        (overlay-put ov 'priority 1000)
                        (push ov my-isearch-all-overlays)
                        (setq match-count (1+ match-count))))))
              (error
               ;; 如果正则表达式有问题，清除高亮
               (my-remove-all-isearch-overlays)))))

        ;; 如果匹配太多，显示警告
        (when (>= match-count max-matches)
          (message "Too many matches (>%d), some may not be highlighted" max-matches))))))

(defun my-isearch-highlight-all-matches ()
  "在 isearch 模式中高亮所有匹配项."
  (when isearch-mode
    (my-highlight-all-matches-delayed)))

(defun my-isearch-cleanup ()
  "isearch 结束时的清理工作."
  (my-remove-all-isearch-overlays)
  (setq my-isearch-last-string "")
  (when my-isearch-highlight-timer
    (cancel-timer my-isearch-highlight-timer)
    (setq my-isearch-highlight-timer nil)))

;; 手动触发的安全版本
(defun my-highlight-all-isearch-matches ()
  "手动高亮当前 isearch 字符串的所有匹配."
  (interactive)
  (if isearch-mode
      (my-highlight-all-matches-now)
    (user-error "Not in isearch mode")))

(provide 'my-isearch-highlight-all)

;;; my-isearch-highlight-all.el ends here