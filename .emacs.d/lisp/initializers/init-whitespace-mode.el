;;; -*- lexical-binding: t -*-
(require 'whitespace)
(global-whitespace-mode 1)
(setq whitespace-style '(face trailing tabs tab-mark))
(setq whitespace-line-column 85)
(setq whitespace-display-mappings '((tab-mark ?\t [?\x2023 ?\t] [?\\ ?\t]) ; tab
                                     (newline-mark ?\n [?\x203a ?\n] [?\\ ?\n])))
;; (setq whitespace-display-mappings '((tab-mark ?\t [?\x203a ?\t] [?\\ ?\t]) ; tab
;;                                      (newline-mark ?\n [?\x203a ?\n] [?\\ ?\n])))
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)

;; 例外：Makefile 语法强制 TAB；Go 官方风格用 TAB
(defun my-indent-with-tabs ()
  (setq indent-tabs-mode t))
(add-hook 'makefile-mode-hook #'my-indent-with-tabs)
(add-hook 'go-mode-hook       #'my-indent-with-tabs)

;; 让 ‣ (U+2023) 使用与主字体行高一致的字体，避免 Arial Unicode MS fallback 导致偏高
(set-fontset-font t #x2023 (font-spec :family "Sarasa Mono SC") nil 'prepend)

(add-hook 'prog-mode-hook #'delete-trailing-whitespace-mode)

(provide 'init-whitespace-mode)
