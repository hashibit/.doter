;;; -*- lexical-binding: t -*-
;;; my-super-keys.el --- Global s- (Cmd) key bindings

;;; Commentary:

;; Global key bindings that use the super (Cmd) modifier.
;; Terminal Emacs does not get these keys.
;; s- keys inside `my-keys-minor-mode-map' stay in my-key-bindings.el.

;;; Code:

(bind-key* "s-j" #'my-toggle-vterm)

(bind-key "M-s-o"  #'ff-find-other-file)

(bind-key* "s-w" #'kill-current-buffer)
(bind-key "s-K" #'my/eldoc-box-show-type-definition)
(bind-key* "s-t" #'tab-bar-new-tab)
(bind-key* "s-n" #'+funcs/new-empty-buffer)
(bind-key* "s-N" #'make-frame)

(defun my-eat-new-in-same-window ()
  (interactive)
  (let ((display-buffer-overriding-action '(display-buffer-same-window)))
    (eat nil t)))
(bind-key* "s-T" #'my-eat-new-in-same-window)

(bind-key* "s-o" #'eat-floating-toggle)

(defun my-s-c()
  (interactive)
  (if (derived-mode-p 'eat-mode)
      (my-eat-copy-region)
    (call-interactively #'kill-ring-save)))

(bind-key "s-c" #'my-s-c)
(defun my-s-v ()
  (interactive)
  (if (derived-mode-p 'eat-mode)
      (eat-yank)
    (yank)))
(bind-key "s-v" #'my-s-v)
;; Emacs >= 28: yank 不再自行删除 active region，改由 delete-selection-mode 的
;; pre-hook 按 this-command 的 delete-selection 属性处理。my-s-v 是包装函数，
;; 必须显式声明，否则粘贴不会替换选区（文本重叠）。eat 里返回 nil 保持原样。
(put 'my-s-v 'delete-selection
     (lambda () (unless (derived-mode-p 'eat-mode) 'yank)))
(bind-key "s-a" #'mark-whole-buffer)

(bind-key "s-<backspace>" #'my-delete-to-bol)

(bind-key* "s-h" #'tab-previous)
(bind-key* "s-l" #'tab-next)
;; tab-bar-select-tab 从按键的数字读取 tab 序号
(bind-key* "s-1" #'tab-bar-select-tab)
(bind-key* "s-2" #'tab-bar-select-tab)
(bind-key* "s-3" #'tab-bar-select-tab)
(bind-key* "s-4" #'tab-bar-select-tab)
(bind-key* "s-5" #'tab-bar-select-tab)
(bind-key* "s-6" #'tab-bar-select-tab)
(bind-key* "s-7" #'tab-bar-select-tab)
(bind-key* "s-8" #'tab-bar-select-tab)
(bind-key* "s-9" #'tab-last)

;; (bind-key* "s-b" #'treemacs)

(bind-key "s-[" #'my-indent-rigidly-left)
(bind-key "s-]" #'my-indent-rigidly-right)

;; 定义向左缩进函数（每次移动 tab-width 个空格）
(defun my-indent-rigidly-left (start end)
  "向左 rigidly 缩进选中区域一个 tab-width。"
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (line-beginning-position) (line-end-position))))
  ;; 禁止任何命令 deactive mark
  (let ((deactivate-mark nil))
    (indent-rigidly start end (- tab-width))))

;; 定义向右缩进函数（每次移动 tab-width 个空格）
(defun my-indent-rigidly-right (start end)
  "向右 rigidly 缩进选中区域一个 tab-width。"
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (line-beginning-position) (line-end-position))))
  ;; 禁止任何命令 deactive mark
  (let ((deactivate-mark nil))
    (indent-rigidly start end tab-width)))


(provide 'my-super-keys)

;;; my-super-keys.el ends here
