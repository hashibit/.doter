;; -*- lexical-binding: t -*-
;;; init-autopep8.el --- py-autopep8 configuration

;;; Code:

(use-package py-autopep8
  :defer t
  :config (setq py-autopep8-options '("--max-line-length=100"))
  :hook
  (python-mode . py-autopep8-mode)
  (python-ts-mode . py-autopep8-mode))


(provide 'init-autopep8)

;;; init-autopep8.el ends here
