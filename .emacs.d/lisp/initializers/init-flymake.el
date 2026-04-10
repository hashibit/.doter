(use-package flymake
  :hook
  ;; 在支持的语言模式中启用 flymake
  ((prog-mode text-mode) . flymake-mode)

  :config
  ;; 禁用 fringe indicator 显示
  (setq-default flymake-indicator-type nil)
  (setq flymake-fringe-indicator-position nil)
  ;; 自定义不同类型的显示样式
  ;; (setq flymake-error-bitmap '(error))
  ;; (setq flymake-warning-bitmap '(warning))
  ;; (setq flymake-note-bitmap '(note))
  (setq flymake-error-bitmap nil)
  (setq flymake-warning-bitmap nil)
  (setq flymake-note-bitmap nil)

  ;; 如果你想完全移除 fringe icons 并仅依赖于波浪线或其他方式展示错误信息
  (setq flymake-fringe-indicators '((error . nil)
                                     (warning . nil)
                                     (note . nil)))

  ;; Face configuration moved to custom-set-faces

  ;; 完全禁用 before-string 指示符（即不显示 ! ? 等）
  (defun my/flymake-no-indicator (_type _pos)
    "Return nil to suppress any before-string or fringe indicator."
    (message "no indicator")
    nil)
  (setq flymake-fringe-indicators '((error . nil) (warning . nil) (note . nil)))
  ;; 关键：覆盖 indicator 生成函数
  ;; (fset 'flymake--make-indicator-function 'my/flymake-no-indicator)
  ;; 关键：使用 push 添加 before-string . nil 到 flymake-overlay-control
  (push '(before-string . nil) (get :error 'flymake-overlay-control))
  (push '(before-string . nil) (get :warning 'flymake-overlay-control))
  (push '(before-string . nil) (get :note 'flymake-overlay-control))

  ;; 强制移除 before-string 的 advice
  (defun my/flymake-remove-before-string (&rest _)
    "Remove before-string from all flymake overlays."
    (dolist (ov (overlays-in (point-min) (point-max)))
      (when (overlay-get ov 'flymake-overlay)
        (overlay-put ov 'before-string nil))))
  ;; Advice 多个关键函数
  (advice-add 'flymake--handle-report :after #'my/flymake-remove-before-string)

  ;; 添加一个快捷键来手动触发 flymake 检查
  (define-key flymake-mode-map (kbd "C-c C-f") #'flymake-start)
  (define-key flymake-mode-map (kbd "C-c F") #'flymake-goto-next-error)

  ;; 如果你想要在保存文件时自动运行 flymake 检查
  (add-hook 'before-save-hook #'flymake-start nil t)
  )


(setq should-i-enable-flymake t)
(defun please-enable-flymake() (setq should-i-enable-flymake t))
(defun please-disable-flymake() (setq should-i-enable-flymake nil))
(defun i-should-enable-flymake() (eq should-i-enable-flymake t))

(setq-default backup-eglot--current-flymake-report-fn nil)



(defun try-stop-flymake (&rest _)
  (please-disable-flymake)
  (flymake-mode 1)
  (when (boundp 'eglot--current-flymake-report-fn)
    (setq backup-eglot--current-flymake-report-fn eglot--current-flymake-report-fn)
    (setq eglot--current-flymake-report-fn nil)
    )
  )

(defun try-start-flymake (&rest _)
  (please-enable-flymake)
  (run-with-timer 0.3 nil #'(lambda()
                              (when (i-should-enable-flymake)
                                (when backup-eglot--current-flymake-report-fn
                                  (setq eglot--current-flymake-report-fn backup-eglot--current-flymake-report-fn)
                                  (setq backup-eglot--current-flymake-report-fn nil))
                                (flymake-mode 1)
                                (flymake-start)
                                )
                              )))



;;
;; deprecated, use sideline to display flymake messages
;;
;; (use-package flymake-diagnostic-at-point
;;   :load-path "~/.emacs.d/lisp/flymake-diagnostic-at-point.el"
;;   :after flymake
;;   :config
;;   (setq flymake-start-syntax-check-on-find-file nil)
;;   (setq flymake-diagnostic-at-point-error-prefix " > ")
;;   (setq flymake-diagnostic-at-point-display-diagnostic-function
;;     'flymake-diagnostic-at-point-display-posframe)
;;   (unless (display-graphic-p)
;;     (setq flymake-diagnostic-at-point-display-diagnostic-function
;;       'flymake-diagnostic-at-point-display-minibuffer))
;;   (add-hook 'flymake-mode-hook #'flymake-diagnostic-at-point-mode)
;;
;;   ;; set faces
;;   (set-face-attribute 'flymake-diagnostic-at-point-posframe-background-face nil :background "dark magenta")
;;   (set-face-attribute 'flymake-error nil :foreground "DeepPink" :underline t)
;;   (set-face-attribute 'flymake-error-echo nil)
;;   (set-face-attribute 'flymake-warning nil :weight 'normal)
;;   (set-face-attribute 'flymake-warning-echo nil)
;;   )






;;
;; deprecated, use flymake-posframe.
;;
;; (use-package flymake-diagnostic-at-point
;;   :after flymake
;;   :config
;;   (add-hook 'flymake-mode-hook #'flymake-diagnostic-at-point-mode))





(provide 'init-flymake)
