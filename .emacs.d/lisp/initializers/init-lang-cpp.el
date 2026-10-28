;; -*- lexical-binding: t -*-
;;; init-lang-cpp.el --- C/C++ language configuration

;; Load clang-format and cff on first use, not at startup.
;; clang-format-buffer and clang-format-region are package autoloads.
;; (require 'clang-format)
;; (require 'cff)

;;; Code:

(autoload 'cff-find-other-file "cff" nil t)
(require 's)

(require 'init-cmake-project)

(defun my-get-clang-format-option (config-str field is-num)
  "Retrieve a config option from a clang-format config.

CONFIG-STR is a string containing the entire clang-format config.
FIELD is specific option, e.g. `IndentWidth'.  IS-NUM is a
boolean that should be set to 1 if the option is numeric,
otherwise assumed alphabetic."
  (if is-num
      (let ((primary-match (s-match (concat "^" field ":[ \t]*[0-9]+") config-str)))
        (if primary-match
            (string-to-number (car (s-match "[0-9]+" (car primary-match))))
          0))
    (let ((primary-match (s-match (concat "^" field ":[ \t]*[A-Za-z]+") config-str)))
      (if primary-match
          (car (s-match "[A-Za-z]+$" (car primary-match)))
        ""))))


(defvar my-clang-format-config-cache (make-hash-table :test #'equal)
  "Cache of `clang-format -dump-config' output, keyed by .clang-format path.
Each value is (MTIME . CONFIG-STRING).")

(defun my-clang-format-config ()
  "Return the dumped clang-format config for the current buffer, or nil.
Only runs clang-format when a .clang-format/_clang-format file dominates
`default-directory'; results are cached until that file changes."
  (when-let* ((dir (locate-dominating-file
                    default-directory
                    (lambda (d)
                      (or (file-exists-p (expand-file-name ".clang-format" d))
                          (file-exists-p (expand-file-name "_clang-format" d))))))
              (file (let ((f (expand-file-name ".clang-format" dir)))
                      (if (file-exists-p f) f (expand-file-name "_clang-format" dir))))
              (mtime (file-attribute-modification-time (file-attributes file))))
    (let ((cached (gethash file my-clang-format-config-cache)))
      (if (and cached (time-equal-p (car cached) mtime))
          (cdr cached)
        (let* ((default-directory dir)
               (config (ignore-errors
                         (string-join (process-lines "clang-format" "-dump-config") "\n"))))
          (when config
            (puthash file (cons mtime config) my-clang-format-config-cache))
          config)))))

(defun my-set-indent-from-clang-format()
  "Set indentation and tab settings based on .clang-format configuration."
  (interactive)
  (when-let* ((clang-format-config (my-clang-format-config)))
    (let ((c-offset (my-get-clang-format-option clang-format-config "IndentWidth" t))
          (tabs-str (my-get-clang-format-option clang-format-config "UseTab" nil))
          ;; -dump-config 会展开 BasedOnStyle，IndentWidth 总是存在，下面的分支只作兜底
          (base-style
           (my-get-clang-format-option clang-format-config "BasedOnStyle" nil)))
      (message "in .clang-format c-offset: %s" c-offset)
      (if (> c-offset 0)
          (setq-local c-ts-indent-offset c-offset)
        (if (not (equal "" base-style))
            (cond ((or (equal "LLVM" base-style)
                       (equal "Google" base-style)
                       (equal "Chromium" base-style)
                       (equal "Mozilla" base-style))
                   (setq-local c-ts-indent-offset 2))
                  ((equal "WebKit" base-style)
                   (setq-local c-ts-indent-offset 4)))))
      ;; 全局默认 indent-tabs-mode 为 nil；只在 .clang-format 明确要求 TAB 时覆盖
      (when (and (not (equal "" tabs-str))
                 (not (string-equal "Never" tabs-str)))
        (setq-local indent-tabs-mode t))
      (if (functionp 'indent-bars-reset)
          (indent-bars-reset)))))


(defun my-c-indent-region-clang-format (start end &optional _quiet)
  "Format region START..END with clang-format; replaces `c-indent-region'."
  (clang-format-region start end))
(advice-add 'c-indent-region :override #'my-c-indent-region-clang-format)

(defvar c-ts-mode-map)
(defvar c++-ts-mode-map)
(declare-function c-ts-mode-toggle-comment-style "c-ts-mode")

(with-eval-after-load 'c-ts-mode
  (dolist (map (list c-ts-mode-map c++-ts-mode-map))
    (keymap-set map "C-c C-e" #'clang-format-region)
    (keymap-set map "C-c C-f" #'clang-format-buffer)
    (keymap-set map "C-c C-c" #'compile)
    (keymap-set map "M-o" #'cff-find-other-file)))

(defun my-c-ts-mode-hook()
  "Hook for C/C++ tree-sitter modes."
  ;; line coment, double forward slash
  (c-ts-mode-toggle-comment-style -1)
  (add-hook 'before-save-hook #'clang-format-buffer nil 'local) ;; add-hook for buffer local, nice!
  (format-all-mode -1) ;; 只用 clang-format，关掉 format-all 避免双重格式化
  (my-set-indent-from-clang-format))


(add-hook 'c++-ts-mode-hook #'my-c-ts-mode-hook)
(add-hook 'c-ts-mode-hook #'my-c-ts-mode-hook)




;; (add-hook 'c-mode-hook 'my-maybe-cmake-project-mode)
;; (add-hook 'c++-mode-hook 'my-maybe-cmake-project-mode)
;; (add-hook 'cmake-mode-hook 'my-maybe-cmake-project-mode)

(add-hook 'c-ts-mode-hook #'my-maybe-cmake-project-mode)
(add-hook 'c++-ts-mode-hook #'my-maybe-cmake-project-mode)
(add-hook 'cmake-ts-mode-hook #'my-maybe-cmake-project-mode)



;; (defun my-rtags-find-symbol-at-point()
;;   (interactive)
;;   (rtags-find-symbol-at-point)
;;   (recenter)
;; )
;;;;    ;;
;;;;    ;;
;;;;    ;; (use-package rtags
;;;;    ;;   :ensure t
;;;;    ;;   :hook
;;;;    ;;   (c++-mode . rtags-start-process-unless-running)
;;;;    ;;   (c-mode . rtags-start-process-unless-running)
;;;;    ;;   :config
;;;;    ;;   (setq rtags-completions-enabled t)
;;;;    ;;   (setq rtags-use-helm t)
;;;;    ;;   (setq rtags-display-result-backend 'helm)
;;;;    ;;   :bind (
;;;;    ;;        ("C-c e" . my-rtags-find-symbol-at-point)
;;;;    ;;        ("C-c n" . rtags-location-stack-forward)
;;;;    ;;        ("C-c b" . rtags-location-stack-back)
;;;;    ;;        ("C-c u" . rtags-imenu)
;;;;    ;;        ("C-c r E" . rtags-find-symbol)
;;;;    ;;        ("C-c r O" . rtags-find-references)
;;;;    ;;        ("C-c r o" . rtags-find-references-at-point)
;;;;    ;;        ("C-c r s" . rtags-find-file)
;;;;    ;;        ("C-c r v" . rtags-find-virtuals-at-point)
;;;;    ;;        ("C-c r F" . rtags-fixit)
;;;;    ;;        ("C-c r P" . rtags-preprocess-file)
;;;;    ;;        ("C-c r R" . rtags-rename-symbol)
;;;;    ;;        ("C-c r x" . rtags-show-rtags-buffer)
;;;;    ;;        ("C-c r T" . rtags-print-symbol-info)
;;;;    ;;        ("C-c r t" . rtags-symbol-type)
;;;;    ;;        ("C-c r I" . rtags-include-file)
;;;;    ;;        ("C-c r i" . rtags-get-include-file-for-symbol)))



(provide 'init-lang-cpp)

;;; init-lang-cpp.el ends here
