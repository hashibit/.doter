(require 'fringe)

(use-package treemacs
  :init
  :config
  (setq treemacs-hide-gitignored-files-mode 1)
  (setq treemacs-space-between-root-nodes nil)
  (setq treemacs-show-hidden-files t)
  (setq treemacs-show-cursor t)
  (setq treemacs-indentation 2)
  (setq treemacs-persist-file (expand-file-name "~/.emacs.d/.local/treemacs-persist"))
  (setq treemacs-last-error-persist-file
    (expand-file-name "~/.emacs.d/.local/treemacs-persist-at-last-error"))
  (setq treemacs-expand-after-init nil)
  (setq treemacs-width-is-initially-locked nil)
  (setq cursor-type nil)
  (treemacs-follow-mode 0)


  ;; (defun add-pointer-to-str(str) (propertize str 'pointer 'arrow))
  ;; (defun add-pointer-to-str-for-file-node(str) (propertize str 'pointer 'arrow))
  ;; (setq treemacs-file-name-transformer #'add-pointer-to-str-for-file-node)
  ;; (setq treemacs-directory-name-transformer #'add-pointer-to-str)


  (global-set-key (kbd "C-c C-p") treemacs-project-map)
  (global-set-key (kbd "C-c C-w") treemacs-workspace-map)
  ;; (treemacs-resize-icons 26)

  (defun my-add-padding-for-treemacs ()
    (set-window-margins (treemacs-get-local-window) 0 0)
    )

  (defun dim-treemacs-window-background ()
    (set (make-local-variable 'face-remapping-alist) `((default :background ,darker-window-bg-color)
                                                        (fringe :background ,darker-window-bg-color)))
    )

  (defun my-reset-treemacs-width ()
    (interactive)
    (setq-default treemacs-width 35)
    ;; call inner api
    (treemacs--set-width 35))

  (defun my-decrease-treemacs-width ()
    (interactive)
    ;; call inner api
    (treemacs--set-width 25))

  (defun my-increase-treemacs-width ()
    (interactive)
    ;; call inner api
    (treemacs--set-width (/ (frame-width) 3)))

  (defun my-treemacs-mark-or-unmark-path-at-point()
    (interactive)
    (treemacs-mark-or-unmark-path-at-point)
    (next-line)
    )

  (defun my-projectile-find-file-in-treemacs()
    (interactive)
    (let ((root (projectile-acquire-root)))
      (advise-once 'pop-to-buffer-same-window :before (lambda (&rest _) (other-window 1)))
      (projectile-find-file-in-directory root)))

  (defun my-treemacs-duplicate-current-file ()
    (interactive)
    (let* ((source (treemacs--prop-at-point :path))
            (destination (treemacs--parent-dir source))
            (target-name (treemacs--filename source))
            (target (->>
                      target-name
                      (treemacs-join-path
                        destination)
                      (treemacs--find-repeated-file-name)))
            (copy-fn (if (file-directory-p source)
                       #'copy-directory
                       #'copy-file)))
      (funcall copy-fn source target)
      (treemacs-refresh)))

  (defun my-treemacs-delete-marked-or-current-file-without-confirm()
    (interactive)
    (with-simulated-input ("yes" "RET")
      (if (bound-and-true-p treemacs--marked-paths)
        (treemacs-delete-marked-paths)
        (treemacs-delete-file)
        ))
    (treemacs-refresh))

  (defun my-treemacs-copy-marked-files-without-confirm()
    (interactive)
    (with-simulated-input ("RET")
      (if (eq treemacs--marked-paths nil)
        (message "no marked files.")
        (treemacs-copy-marked-files)
        (treemacs-refresh))))


  (defun display-treemacs-widow-in-ace-window-selection ()
    (setq aw-ignored-buffers
      (delete 'treemacs-mode aw-ignored-buffers)))

  ;;;; custom highlight for treemacs current line
  (defface my-treemacs-custom-line-highlight
    '((t (:background "#292929" :weight normal)))
    "")
  (defun change-treemacs-hl-line-mode ()
    (setq-local hl-line-face 'my-treemacs-custom-line-highlight)
    (overlay-put hl-line-overlay 'face hl-line-face)
    ;; (overlay-put hl-line-overlay 'pointer 'arrow)
    )


  ;; CAUTION: private api. copied from treemacs-core-utils.el
  ;; because i want _Copy1 instead of (Copy 1)
  (defun treemacs--find-repeated-file-name (path)
    "Find a fitting copy name for given file PATH.
Returns a name in the /file/name_Copy1.ext.  If that also already
exists it returns /file/name_Copy2.ext etc."
    (let* ((n 0)
            (dir (treemacs--parent-dir path))
            (filename (treemacs--filename path))
            (filename-no-ext (file-name-sans-extension path))
            (ext (--when-let (file-name-extension filename) (concat "." it)))
            (template "_Copy%d")
            (new-path path))
      (while (file-exists-p new-path)
        (cl-incf n)
        (setf new-path (treemacs-join-path dir (concat filename-no-ext (format template n) ext))))
      new-path))

  ;;
  ;; 隐藏 python 的一些忽略文件
  ;;
  (defun my/treemacs-ignore-pycache-and-egg-info (file-name abs-path)
    "Ignore __pycache__ directories and *.egg-info directories."
    (or
      ;; 忽略名为 __pycache__ 的目录
      (string= file-name "__pycache__")
      ;; 忽略以 .egg-info 结尾的目录
      (string-suffix-p ".egg-info" file-name)
      ;; 可选：忽略 .pyc 文件（如果你也想隐藏单个 .pyc）
      ;; (string-suffix-p ".pyc" file-name)
      ))
  (add-to-list 'treemacs-ignored-file-predicates #'my/treemacs-ignore-pycache-and-egg-info)


  ;; 鼠标放上去的效果，加了下划线和 hl line 的背景色
  (defface treemacs-button-underline-only
    '((t :underline t :foreground "unspecified" :background "unspecified" :box nil :inherit 'my-treemacs-custom-line-highlight))
    "Face that only adds an underline on hover, no background color."
    :group 'treemacs-faces)
  (put 'treemacs-button 'mouse-face 'treemacs-button-underline-only)

  (add-hook 'treemacs-mode-hook #'my-add-padding-for-treemacs)
  (add-hook 'treemacs-mode-hook #'display-treemacs-widow-in-ace-window-selection)
  (add-hook 'treemacs-mode-hook #'dim-treemacs-window-background)
  (add-hook 'treemacs-mode-hook #'change-treemacs-hl-line-mode)
  (add-hook 'treemacs-mode-hook #'my-special-buffer-keys-minor-mode)
  ;; (add-hook 'treemacs-mode-hook #'my-set-large-line-height)
  :bind
  (:map
    treemacs-mode-map
    ("=" . my-reset-treemacs-width)
    ("F" . my-projectile-find-file-in-treemacs)
    ("M" . my-treemacs-mark-or-unmark-path-at-point)
    ("U" . treemacs-reset-marks)
    ("H" . my-decrease-treemacs-width)
    ("L" . my-increase-treemacs-width)
    ("C" . treemacs-copy-file)
    ("D" . my-treemacs-duplicate-current-file)
    ("P" . my-treemacs-copy-marked-files-without-confirm)
    ("C-d" . my-treemacs-delete-marked-or-current-file-without-confirm)
    ("a" . treemacs-create-file)
    ("n" . my-isearch-forward)
    ("N" . my-isearch-backward)
    ("A" . treemacs-create-dir)
    ("s-F" . deadgrep)
    ;; add-hook no work????
    ;; ("<mouse-1>" . treemacs-single-click-expand-action)
    ("<double-mouse-1>" . treemacs-RET-action)
    ))


(with-eval-after-load 'treemacs

  ; (treemacs-create-theme "simple"
  ;   :config
  ;   (progn
  ;     (treemacs-create-icon :icon (format "%s\t" (all-the-icons-octicon "repo" :height 1.2 :v-adjust -0.1 :face 'font-lock-string-face))
  ;                           :extensions (root-closed root-open)
  ;                           :fallback 'same-as-icon)
  ;     (treemacs-create-icon :icon (format "%s%s" (all-the-icons-material "expand_more" :height 1.2 :v-adjust -0.2 :face 'default)
  ;                                         (propertize " " 'display '(space . (:width (0)))))
  ;                           :extensions (dir-open)
  ;                           :fallback 'same-as-icon)
  ;     (treemacs-create-icon :icon (format "%s%s" (all-the-icons-material "chevron_right" :height 1.2 :v-adjust -0.2 :face 'default)
  ;                                         (propertize " " 'display '(space . (:width (0)))))
  ;                           :extensions (dir-closed)
  ;                           :fallback 'same-as-icon)
  ;     (treemacs-create-icon :icon (propertize " " 'display '(space . (:width (18))))
  ;                           :extensions (fallback)
  ;                           :fallback 'same-as-icon)))

  ;; terminal mode use simple theme
  (if (display-graphic-p)
    (progn
      (require 'treemacs-all-the-icons)
      (treemacs-load-theme "all-the-icons"))
    (treemacs-load-theme "Default")
    )
  ;;
  )


;; 例如 12pt = 120
(if (my-system-type-is-darwin)
  (defvar my-font-height 130)
  (defvar my-font-height 110))

;; 只设置 :height，其他属性由 custom-set-faces 提供
(with-eval-after-load 'treemacs
  (dolist (face '(
                   tab-bar
                   treemacs-directory-collapsed-face
                   treemacs-directory-face
                   treemacs-file-face
                   treemacs-git-added-face
                   treemacs-git-conflict-face
                   treemacs-git-ignored-face
                   treemacs-git-modified-face
                   treemacs-git-renamed-face
                   treemacs-git-unmodified-face
                   treemacs-git-untracked-face
                   treemacs-root-face
                   treemacs-tags-face))
    (set-face-attribute face nil :height 0.9))
  )


(with-eval-after-load 'cfrs
  ;; CFRS face configuration moved to custom-set-faces
  )


(defun my-treemacs-add-and-display-current-project ()
  (interactive)
  (with-selected-window (get-buffer-window (current-buffer))
    (treemacs-add-and-display-current-project))
  (treemacs-find-file)
  (treemacs-select-window)
  (when (display-graphic-p)
    (setq-local cursor-type 'box)))



(provide 'init-treemacs)
