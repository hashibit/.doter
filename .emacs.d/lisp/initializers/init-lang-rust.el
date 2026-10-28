;; -*- lexical-binding: t -*-
;;; init-lang-rust.el --- Rust Language Configuration

;;; Commentary:
;;
;;  Rust programming language support
;;

;;; Code:

(declare-function rust-ts-flymake "rust-ts-mode")
(declare-function treesit-font-lock-recompute-features "treesit")

(defun my-rust-ts-mode-setup ()
  "Buffer-local setup for `rust-ts-mode'."
  ;; 诊断交给 eglot (rust-analyzer)，不用 clippy-driver
  (remove-hook 'flymake-diagnostic-functions #'rust-ts-flymake t)
  ;; Don't highlight ERROR nodes — incomplete syntax while typing is normal
  (treesit-font-lock-recompute-features nil '(error)))

(add-hook 'rust-ts-mode-hook #'my-rust-ts-mode-setup)

(use-package rust-mode
  :ensure t
  :defer t)



(provide 'init-lang-rust)

;;; init-lang-rust.el ends here
