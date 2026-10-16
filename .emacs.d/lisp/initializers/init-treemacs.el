;;; -*- lexical-binding: t -*-
(require 'fringe)
(eval-when-compile (require 'dash))

(defvar darker-window-bg-color)
(defvar my-window-margins)
(defvar aw-ignored-buffers)
(defvar hl-line-overlay)
(defvar treemacs--marked-paths)
(defvar treemacs-width)
(declare-function treemacs-hide-gitignored-files-mode "treemacs-async")
(declare-function treemacs-follow-mode "treemacs-follow-mode")
(declare-function treemacs-get-local-window "treemacs-scope")
(declare-function treemacs-set-width "treemacs-interface")
(declare-function treemacs-mark-or-unmark-path-at-point "treemacs-file-management")
(declare-function treemacs--prop-at-point "treemacs-core-utils")
(declare-function treemacs--parent-dir "treemacs-core-utils")
(declare-function treemacs--filename "treemacs-core-utils")
(declare-function treemacs-join-path "treemacs-core-utils")
(declare-function treemacs-refresh "treemacs-interface")
(declare-function treemacs-delete-marked-paths "treemacs-file-management")
(declare-function treemacs-delete-file "treemacs-file-management")
(declare-function treemacs-copy-marked-files "treemacs-file-management")
(declare-function treemacs-load-theme "treemacs-themes")
(declare-function treemacs-add-and-display-current-project "treemacs")
(declare-function treemacs-find-file "treemacs")
(declare-function treemacs-select-window "treemacs")
(declare-function projectile-acquire-root "projectile")
(declare-function projectile-find-file-in-directory "projectile")

(defun my-add-padding-for-treemacs ()
  ;; treemacs 窗口不要边距（见 init-god 的 my/set-margins-all-windows）
  (setq-local my-window-margins '(0 . 0))
  (when-let* ((window (treemacs-get-local-window)))
    (set-window-margins window 0 0)))

;; treemacs 自己把 default/fringe remap 到 treemacs-window-background-face
(defun dim-treemacs-window-background ()
  (set-face-attribute 'treemacs-window-background-face nil
                      :background darker-window-bg-color))

(defun my-reset-treemacs-width ()
  (interactive)
  (setq-default treemacs-width 35)
  (treemacs-set-width t))

(defun my-decrease-treemacs-width ()
  (interactive)
  (let ((treemacs-width 25))
    (treemacs-set-width t)))

(defun my-increase-treemacs-width ()
  (interactive)
  (let ((treemacs-width (/ (frame-width) 3)))
    (treemacs-set-width t)))

(defun my-treemacs-mark-or-unmark-path-at-point()
  (interactive)
  (treemacs-mark-or-unmark-path-at-point)
  (line-move 1))

;; 在 treemacs 之外最近使用的窗口打开文件
(defun my-projectile-find-file-in-treemacs()
  (interactive)
  (let ((root (projectile-acquire-root))
        (display-buffer-overriding-action
         '(display-buffer-use-some-window
           (inhibit-same-window . t)
           (some-window . mru))))
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
                    (my-treemacs--find-repeated-file-name)))
          (copy-fn (if (file-directory-p source)
                     #'copy-directory
                     #'copy-file)))
    (funcall copy-fn source target)
    (treemacs-refresh)))

(defun my-treemacs-delete-marked-or-current-file-without-confirm()
  (interactive)
  (cl-letf (((symbol-function 'yes-or-no-p) #'always))
    (if (bound-and-true-p treemacs--marked-paths)
      (treemacs-delete-marked-paths)
      (treemacs-delete-file)))
  (treemacs-refresh))

;; 直接复制到当前目录（相当于在目录提示里直接回车）
(defun my-treemacs-copy-marked-files-without-confirm()
  (interactive)
  (if (null treemacs--marked-paths)
    (message "no marked files.")
    (cl-letf (((symbol-function 'read-directory-name)
               (lambda (&rest _) default-directory)))
      (treemacs-copy-marked-files))
    (treemacs-refresh)))


(defun display-treemacs-widow-in-ace-window-selection ()
  (with-eval-after-load 'ace-window
    (setq aw-ignored-buffers
      (delete 'treemacs-mode aw-ignored-buffers))))

;;;; custom highlight for treemacs current line
(defface my-treemacs-custom-line-highlight
  '((t (:background "#292929" :weight normal)))
  "Custom hl-line face for treemacs."
  :group 'treemacs-faces)
(defun change-treemacs-hl-line-mode ()
  (setq-local hl-line-face 'my-treemacs-custom-line-highlight)
  (when (overlayp hl-line-overlay)
    (overlay-put hl-line-overlay 'face hl-line-face))
  ;; (overlay-put hl-line-overlay 'pointer 'arrow)
  )


;; CAUTION: overrides private api `treemacs--find-repeated-file-name'
;; (copied from treemacs-core-utils.el) because i want _Copy1 instead of (Copy 1)
(defun my-treemacs--find-repeated-file-name (path)
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
(defun my/treemacs-ignore-pycache-and-egg-info (file-name _abs-path)
  "Ignore __pycache__ directories and *.egg-info directories."
  (or
    ;; 忽略名为 __pycache__ 的目录
    (string= file-name "__pycache__")
    ;; 忽略以 .egg-info 结尾的目录
    (string-suffix-p ".egg-info" file-name)
    ;; 可选：忽略 .pyc 文件（如果你也想隐藏单个 .pyc）
    ;; (string-suffix-p ".pyc" file-name)
    ))


;; 鼠标放上去的效果，加了下划线和 hl line 的背景色
(defface my-treemacs-button-underline-only
  '((t :underline t :box nil :inherit my-treemacs-custom-line-highlight))
  "Face for hovered treemacs buttons: underline plus the custom line highlight."
  :group 'treemacs-faces)

(use-package treemacs
  :config
  ;; Only sets the variable; actually enabling the mode
  ;; ((treemacs-hide-gitignored-files-mode 1)) breaks rendering with
  ;; "Wrong type argument: treemacs-dom-node, nil".
  (setq treemacs-hide-gitignored-files-mode 1)
  (setq treemacs-space-between-root-nodes nil)
  (setq treemacs-show-hidden-files t)
  (setq treemacs-show-cursor t)
  (setq treemacs-indentation 2)
  (setq treemacs-persist-file (locate-user-emacs-file ".local/treemacs-persist"))
  (setq treemacs-last-error-persist-file
    (locate-user-emacs-file ".local/treemacs-persist-at-last-error"))
  (setq treemacs-expand-after-init nil)
  (setq treemacs-width-is-initially-locked nil)
  (treemacs-follow-mode 0)


  ;; (defun add-pointer-to-str(str) (propertize str 'pointer 'arrow))
  ;; (defun add-pointer-to-str-for-file-node(str) (propertize str 'pointer 'arrow))
  ;; (setq treemacs-file-name-transformer #'add-pointer-to-str-for-file-node)
  ;; (setq treemacs-directory-name-transformer #'add-pointer-to-str)


  (keymap-global-set "C-c C-p" treemacs-project-map)
  (keymap-global-set "C-c C-w" treemacs-workspace-map)
  ;; (treemacs-resize-icons 26)

  (advice-add 'treemacs--find-repeated-file-name :override #'my-treemacs--find-repeated-file-name)
  (add-to-list 'treemacs-ignored-file-predicates #'my/treemacs-ignore-pycache-and-egg-info)
  (put 'treemacs-button 'mouse-face 'my-treemacs-button-underline-only)

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
(defvar my-font-height (if (my-system-type-is-darwin) 130 110))

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


;; CFRS face configuration moved to custom-set-faces


(defun my-treemacs-add-and-display-current-project ()
  (interactive)
  (with-selected-window (get-buffer-window (current-buffer))
    (treemacs-add-and-display-current-project))
  (treemacs-find-file)
  (treemacs-select-window)
  (when (display-graphic-p)
    (setq-local cursor-type 'box)))



(provide 'init-treemacs)
