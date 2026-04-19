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
        (delq 'rust-ts-flymake flymake-diagnostic-functions))))
  :ensure t)



(provide 'init-lang-rust)

;;; init-lang-rust.el ends here
