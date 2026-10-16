;;; -*- lexical-binding: t -*-
;; load from ./lisp
(require 'nice-jumper)
(global-nice-jumper-mode t)
;; (add-hook 'nice-jumper-post-jump-hook 'my-recenter)
(add-hook 'nice-jumper-post-jump-hook 'xref-pulse-momentarily)


(defvar my/nice-jumper--in-progress nil)

;; 只监听 xref 层面的跳转，防止重复
(with-eval-after-load 'xref
  (dolist (func '(xref-find-definitions
                  xref-find-references
                  xref-pop-marker-stack
                  xref-find-definitions-at-mouse
                  xref-find-references-at-mouse))
    (advice-add func :before #'my/nice-jumper-record-jump)))

;; imenu 不经过 xref，所以单独处理
(advice-add 'imenu :before #'my/nice-jumper-record-jump)

;; etags / ctags
(advice-add 'find-tag       :before #'my/nice-jumper-record-jump)
(advice-add 'pop-tag-mark   :before #'my/nice-jumper-record-jump)

;; deadgrep（通常也不走 xref）
(with-eval-after-load 'deadgrep
  (advice-add 'deadgrep :before #'my/nice-jumper-record-jump))

;; gtags（根据你使用的包决定是否需要）
(with-eval-after-load 'counsel-gtags
  (advice-add 'counsel-gtags-find-definition :before #'my/nice-jumper-record-jump))

;; helm-gtags
(with-eval-after-load 'helm-gtags
  (advice-add 'helm-gtags-dwim :before #'my/nice-jumper-record-jump))




(defun my/nice-jumper-record-jump (&rest _)
  "记录当前跳转位置到 nice-jumper，防止重复触发。"
  (unless (or my/nice-jumper--in-progress
              nice-jumper--jumping)
    (let ((my/nice-jumper--in-progress t))
      (nice-jumper--set-jump))))

(defun my/nice-jumper-remove-all-advice ()
  "移除所有绑定到 my/nice-jumper-record-jump 的 advice。"
  (interactive)
  (let ((fn #'my/nice-jumper-record-jump))
    (advice-mapc
     (lambda (symbol where)
       (when (eq (advice--car-safe (advice--get symbol where)) fn)
         (advice-remove symbol fn)))
     nil))
  (message "✅ 已移除所有 my/nice-jumper-record-jump 的 advice"))



(provide 'init-nice-jumper)
