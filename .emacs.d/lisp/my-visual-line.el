;; -*- lexical-binding: t -*-
;;; my-visual-line.el --- Visual line selection, copy and kill helpers

(defvar my-visual-line-selection nil)
(defvar my-visual-line-start-num nil)
(defvar my-visual-line-selected nil)


(defun my-set-visual-selected(&rest _)
  (setq my-visual-line-selected t))
;; kill-whole-line 不会触发 deactivate mark，所以我们手动设置 visual-line 模式
(advice-add 'kill-whole-line :after #'my-set-visual-selected)


(defun my-kill-ring-save-advice (orig-fun &rest args)
  (let ((result (apply orig-fun args))) ; 先执行原始的 kill-ring-save
    ;; 如果是 visual line selection 模式，则在复制的内容最后，加上一个换行符
    ;; 用 kill-new 的 REPLACE 参数替换，保证剪贴板也同步
    (when (and my-visual-line-selection
            (stringp (car kill-ring)))
      (kill-new (concat (car kill-ring) "\n") t))
    result))
(advice-add 'kill-ring-save :around #'my-kill-ring-save-advice)

;; 这个会在最后执行，所以做清理动作
(defun my-visual-line-reset-on-deactivate ()
  (setq my-visual-line-selected (and my-visual-line-selection t)
    my-visual-line-selection nil
    my-visual-line-start-num nil))
(add-hook 'deactivate-mark-hook #'my-visual-line-reset-on-deactivate)
(defun my-copy-whole-line-or-region ()
  "智能复制：有选区则复制选区（支持 visual-line），无选区则复制当前行。"
  (interactive)
  (if (use-region-p)
    ;; 有选区：直接调用 kill-ring-save（会触发 advice 加换行）
    (call-interactively #'kill-ring-save)
    ;; 无选区：手动复制当前行
    ;; 标记这是一个行选择
    (setq my-visual-line-selected t)
    ;; 行复制，末尾加换行，只产生一个 kill-ring 条目
    (kill-new (concat (filter-buffer-substring
                        (line-beginning-position) (line-end-position))
                "\n"))
    (message "Copied line")))


(defun my-copy-whole-line-or-region-to-tmux ()
  "Copy the current region or whole line to tmux paste buffer."
  (interactive)
  (let* ((in-region (use-region-p))
         (beg (if in-region (region-beginning) (line-beginning-position)))
         (end (if in-region (region-end) (min (1+ (line-end-position) ) (point-max)))))
    (shell-command-on-region beg end "tmux load-buffer -" nil nil t)
    (message "Copied to tmux buffer")))
(defun my-select-current-line-and-forward-line (_arg)
  "Select the current line and move the cursor by ARG lines IF
  no region is selected.
  If a region is already selected when calling this command, only move
  the cursor by ARG lines."
  (interactive "p")
  (setq my-visual-line-selection t)
  (if (use-region-p)
    (let* ((curr-line (line-number-at-pos))
            (beg (region-beginning))
            (beg-line (line-number-at-pos beg))
            (end (region-end))
            (end-line (line-number-at-pos end)))
      (cond
        ((eq curr-line beg-line)
          (setq my-visual-line-start-num end-line)
          (goto-char end)
          (end-of-line)
          (set-mark-command nil)
          (goto-char beg)
          (beginning-of-line)
          )
        ((eq curr-line end-line)
          (setq my-visual-line-start-num beg-line)
          (goto-char beg)
          (beginning-of-line)
          (set-mark-command nil)
          (goto-char end)
          (end-of-line)
          )
        )
      )
    (setq my-visual-line-start-num (line-number-at-pos))
    (beginning-of-line)
    (set-mark-command nil)
    (end-of-line)))


(provide 'my-visual-line)
