;; -*- lexical-binding: t -*-
;;; init-lang-cpp.el --- C/C++ language configuration

(require 'clang-format)
(require 'cff)

(require 'init-cmake-project)

(defun get-clang-format-option (config-str field is-num)
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


(defun my-set-indent-from-clang-format()
  "Set indentation and tab settings based on .clang-format configuration."
  (interactive)
  (let* ((clang-format-config
          (shell-command-to-string "clang-format -dump-config"))
         (c-offset (get-clang-format-option clang-format-config "IndentWidth" t))
         (tabs-str (get-clang-format-option clang-format-config "UseTab" nil))
         (base-style
          (get-clang-format-option clang-format-config "BasedOnStyle" nil)))
    (progn
      (message "in .clang-format c-offset: %s" c-offset)
      (if (> c-offset 0)
          (setq-local c-ts-mode-indent-offset c-offset)
        (if (not (equal "" base-style))
            (cond ((or (equal "LLVM" base-style)
                       (equal "Google" base-style)
                       (equal "Chromium" base-style)
                       (equal "Mozilla" base-style))
                   (setq-local c-ts-mode-indent-offset 2))
                  ((equal "WebKit" base-style)
                   (setq-local c-ts-mode-indent-offset 4)))))
      ;; 全局默认 indent-tabs-mode 为 nil；只在 .clang-format 明确要求 TAB 时覆盖
      (when (and (not (equal "" tabs-str))
                 (not (string-equal "Never" tabs-str)))
        (setq-local indent-tabs-mode t))
      (if (functionp 'indent-bars-reset)
        (indent-bars-reset)))))


(defun my-c-ts-mode-hook()
  "Hook for C/C++ tree-sitter modes."
  (fset 'c-indent-region 'clang-format-region)
  (bind-keys
   :map c++-ts-mode-map
   ("C-c C-e" . clang-format-region)
   ("C-c C-f" . clang-format-buffer)
   ("C-c C-c" . compile)
   ("M-o" . cff-find-other-file))

   ;; line coment, double forward slash
   (c-ts-mode-toggle-comment-style -1)
   (add-hook 'before-save-hook #'clang-format-buffer nil 'local) ;; add-hook for buffer local, nice!
   (format-all-mode -1) ;; 只用 clang-format，关掉 format-all 避免双重格式化

  (my-set-indent-from-clang-format)
)


(add-hook 'c++-ts-mode-hook #'my-c-ts-mode-hook)
(add-hook 'c-ts-mode-hook #'my-c-ts-mode-hook)




;; (add-hook 'c-mode-hook 'maybe-cmake-project-mode)
;; (add-hook 'c++-mode-hook 'maybe-cmake-project-mode)
;; (add-hook 'cmake-mode-hook 'maybe-cmake-project-mode)

(add-hook 'c-ts-mode-hook 'maybe-cmake-project-mode)
(add-hook 'c++-ts-mode-hook 'maybe-cmake-project-mode)
(add-hook 'cmake-ts-mode-hook 'maybe-cmake-project-mode)



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
