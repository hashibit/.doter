;; -*- lexical-binding: t -*-
;;; init-lang-rust.el --- Rust Language Configuration

;;; Commentary:
;;
;;  Rust programming language support
;;

;;; Code:

(use-package rust-mode
  :config
  (add-hook 'rust-ts-mode-hook
    (lambda ()
      (remove-hook 'flymake-diagnostic-functions #'rust-ts-flymake t)
      (setq-local flymake-diagnostic-functions
        (delq 'rust-ts-flymake flymake-diagnostic-functions))
      ;; Don't highlight ERROR nodes — incomplete syntax while typing is normal
      (setq-local treesit-font-lock-feature-list
        (mapcar (lambda (group) (remq 'error group))
                treesit-font-lock-feature-list))
      (treesit-font-lock-recompute-features)))
  :ensure t)



(provide 'init-lang-rust)

;;; init-lang-rust.el ends here
