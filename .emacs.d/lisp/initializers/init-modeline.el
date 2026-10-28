;; -*- lexical-binding: t -*-
;;; init-modeline.el --- Mode line configuration

;; 保持原始变量定义

;;; Code:

(defvar-local my-buffer-filename-with-git-directory nil
  "Parent directory of the current directory.
This variable is nil if the current buffer isn't visiting a file.")
(put 'my-buffer-filename-with-git-directory 'permanent-local t)

;; 存储完整路径用于 tooltip
(defvar-local my-buffer-full-path nil
  "Full path for tooltip display.")

;; 缩写路径函数
(defun my-abbreviate-file-path (path)
  "Abbreviate directory names in PATH to their first letters.
Example: \"project/src/main/java/File.java\" -> \"p/s/m/j/File.java\""
  (let* ((parts (split-string path "/"))
         (file-part (car (last parts))))
    (string-join
     (mapcar (lambda (part)
               ;; 保持文件名完整，只缩写目录名
               (cond ((or (string-empty-p part) (eq part file-part)) part)
                     ;; 隐藏文件夹保留前两个字符（如 .emacs -> .e）
                     ((string-prefix-p "." part) (substring part 0 (min 2 (length part))))
                     ;; 普通文件夹只保留首字母
                     (t (substring part 0 1))))
             parts)
     "/")))

(defun my-window-active-p ()
  "Return non-nil if the window whose mode line is being drawn is selected."
  (mode-line-window-selected-p))

(defun my-buffer-identification-cached (fmt)
  "Propertize FMT as the buffer identification."
  (list
   (propertize fmt
               'face (if (mode-line-window-selected-p)
                         '(:inherit mode-line-active)
                       'mode-line-buffer-id)
               'help-echo my-buffer-full-path  ;; 添加 tooltip
               'mouse-face 'mode-line-highlight
               'local-map mode-line-buffer-identification-keymap)))

(defun my-set-buffer-filename-with-git-directory-cached ()
  "Set buffer filename with git directory."
  (when (and buffer-file-name buffer-file-truename)
    (let ((full-path
           (or
            (when-let* ((project (project-current))
                        (root (project-root project))
                        (root-parent (file-name-directory (directory-file-name root)))
                        (rel-dir (file-relative-name (file-name-directory buffer-file-truename) root-parent)))
              (concat rel-dir (file-name-nondirectory buffer-file-truename)))
            buffer-file-name)))
      (setq my-buffer-full-path full-path
            my-buffer-filename-with-git-directory
            (if (< (length full-path) 80)
                full-path
              (my-abbreviate-file-path full-path))))))

(defun my-clear-modeline-cache ()
  "Recompute the mode line file name of the current buffer."
  (my-set-buffer-filename-with-git-directory-cached))

(add-hook 'find-file-hook #'my-set-buffer-filename-with-git-directory-cached)

(setq-default mode-line-buffer-identification
              '(:eval (my-buffer-identification-cached
                       (or my-buffer-filename-with-git-directory ""))))

;; Face configuration moved to custom-set-faces

(provide 'init-modeline)

;;; init-modeline.el ends here
