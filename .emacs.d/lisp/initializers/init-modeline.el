;; 保持原始变量定义
(defvar buffer-filename-with-git-directory nil
  "Parent directory of the current directory.
This variable is nil if the current buffer isn't visiting a file.")

(make-variable-buffer-local 'buffer-filename-with-git-directory)
(put 'buffer-filename-with-git-directory 'permanent-local t)

;; 添加缓存变量
(defvar my-buffer-identification-cache nil
  "Cache for buffer identification to avoid repeated computation.")
(make-variable-buffer-local 'my-buffer-identification-cache)

(defvar my-buffer-filename-cache nil
  "Cache for buffer filename with git directory.")
(make-variable-buffer-local 'my-buffer-filename-cache)

(defvar my-buffer-identification-timer nil
  "Timer for clearing cache periodically.")

;; 存储完整路径用于 tooltip
(defvar my-buffer-full-path nil
  "Full path for tooltip display.")
(make-variable-buffer-local 'my-buffer-full-path)

;; 缩写路径函数
(defun abbreviate-file-path (path)
  "Abbreviate directory names in PATH to their first letters.
Example: 'project/src/main/java/File.java' -> 'p/s/m/j/File.java'"
  (let* ((parts (split-string path "/"))
          (abbreviated-parts
            (mapcar (lambda (part)
                      ;; 保持文件名完整，只缩写目录名
                      (if (or (string= part "")
                            (string-suffix-p (file-name-extension path t) part)
                            (string= part (car (last parts))))
                        part
                        ;; 缩写目录名
                        (if (string-match "^\\." part)
                          ;; 隐藏文件夹保留前两个字符（如 .emacs -> .e）
                          (substring part 0 (min 2 (length part)))
                          ;; 普通文件夹只保留首字母
                          (substring part 0 1))))
              parts)))
    (string-join abbreviated-parts "/")))

;; 优化后的窗口活跃状态检查
(defun my-window-active-p ()
  "Check if current window is active with caching."
  (let ((current-window (selected-window)))
    (or (eq current-window (old-selected-window))
      (and (minibuffer-window-active-p (minibuffer-window))
        (with-selected-window (minibuffer-window)
          (eq current-window (minibuffer-selected-window)))))))

;; 缓存的 buffer identification 函数
(defun my-buffer-identification-cached (fmt)
  "Generate buffer identification with caching."
  (let* ((current-window (selected-window))
          (window-active (my-window-active-p))
          (cache-key (list fmt window-active (buffer-modified-p))))

    ;; 检查缓存是否有效
    (unless (and my-buffer-identification-cache
              (equal (car my-buffer-identification-cache) cache-key))
      ;; 重新计算并缓存
      (setq my-buffer-identification-cache
        (cons cache-key
          (list
            (propertize fmt
              'face (if window-active
                      '(:inherit mode-line-active)
                      'mode-line-buffer-id)
              'help-echo my-buffer-full-path  ;; 添加 tooltip
              'mouse-face 'mode-line-highlight
              'local-map mode-line-buffer-identification-keymap)))))

    ;; 返回缓存的结果
    (cdr my-buffer-identification-cache)))

;; 优化后的文件名设置函数
(defun set-buffer-filename-with-git-directory-cached ()
  "Set buffer filename with git directory, using cache."
  (when (and buffer-file-name buffer-file-truename)
    (let ((cache-key (list buffer-file-name buffer-file-truename)))
      (unless (and my-buffer-filename-cache
                (equal (car my-buffer-filename-cache) cache-key))
        (let* ((full-path
                 (or
                   (when-let* ((project (project-current))
                                (root (project-root project))
                                (root-parent (file-name-directory (directory-file-name root)))
                                (rel-dir (file-relative-name (file-name-directory buffer-file-truename) root-parent)))
                     (concat rel-dir (file-name-nondirectory buffer-file-truename)))
                   buffer-file-name))
                (abbreviated-path (if (< (length full-path) 40)
                                    full-path
                                    (abbreviate-file-path full-path) )))

          ;; 存储完整路径用于 tooltip
          (setq my-buffer-full-path full-path)

          ;; 缓存缩写后的路径
          (setq my-buffer-filename-cache
            (cons cache-key abbreviated-path))))

      (setq buffer-filename-with-git-directory (cdr my-buffer-filename-cache)))))

;; 清除缓存的函数
(defun my-clear-modeline-cache ()
  "Clear modeline caches."
  (setq my-buffer-identification-cache nil
    my-buffer-filename-cache nil))

;; 设置 hooks
(add-hook 'find-file-hook 'set-buffer-filename-with-git-directory-cached)

;; 在适当的时候清除缓存
(add-hook 'after-save-hook #'my-clear-modeline-cache)
(add-hook 'window-configuration-change-hook #'my-clear-modeline-cache)

;; 定期清除缓存（避免内存泄漏）
(when my-buffer-identification-timer
  (cancel-timer my-buffer-identification-timer))
(setq my-buffer-identification-timer
  (run-with-idle-timer 5 t #'my-clear-modeline-cache))

;; 使用缓存版本的 buffer identification
(setq-default mode-line-buffer-identification
  `(:eval (my-buffer-identification-cached
            (or buffer-filename-with-git-directory ""))))

;; Face configuration moved to custom-set-faces

(provide 'init-modeline)
