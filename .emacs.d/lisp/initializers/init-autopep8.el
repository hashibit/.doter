;;; -*- lexical-binding: t -*-

(use-package py-autopep8
  :defer t
  :config (setq py-autopep8-options '("--max-line-length=100"))
  :hook
  (python-mode . py-autopep8-mode)
  (python-ts-mode . py-autopep8-mode))


(provide 'init-autopep8)
