;; -*- lexical-binding: t -*-
;;; init-lang-yaml.el --- YAML Language Configuration

;;; Commentary:
;;
;;  YAML file format support
;;

;;; Code:

(use-package yaml-mode
  :ensure t
  :mode ("\\.yml\\'" "\\.yml\\.j2\\'" "\\.yaml\\'" "\\.yaml\\.j2\\'")
  :hook
  (yaml-mode . display-line-numbers-mode)
  (yaml-ts-mode . display-line-numbers-mode))

(provide 'init-lang-yaml)

;;; init-lang-yaml.el ends here