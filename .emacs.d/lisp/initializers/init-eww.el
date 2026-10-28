;; -*- lexical-binding: t -*-
;;; init-eww.el --- Eww configuration

;; eww / shr 默认正文用 variable-pitch（"Sans Serif"），代码用 fixed-pitch（"Monospace"），
;; 都不是 IBM Plex，看着很怪。关掉 shr-use-fonts 后统一用 default face（IBM Plex Mono）。

;;; Code:

;; Package variables, declared for the byte compiler.
(defvar eww-mode-map)

(use-package shr
  :ensure nil
  :defer t
  :config
  (setq shr-use-fonts nil)
  ;; 不显示图片（HyperSpec 里的图标/导航图片），M-I (eww-toggle-images) 可临时打开
  (setq shr-inhibit-images t)
  ;; HyperSpec 把顶部导航图片放在 <H1> 里，图片关掉后替代文字用 shr-h1 (1.3 倍) 显示太大
  (set-face-attribute 'shr-h1 nil :height 1.0))

;; eww buffer 不是 find-file 打开的，find-file-hook 不会触发，这里补上；
;; eww-mode 在 my-special-buffer-modes 里，所以会关掉 god mode、开启 special buffer keys
(add-hook 'eww-mode-hook #'my-init-god-mode-for-new-buffer)

(with-eval-after-load 'eww
  (keymap-set eww-mode-map "H" #'eww-back-url)
  (keymap-set eww-mode-map "L" #'eww-forward-url))


(provide 'init-eww)

;;; init-eww.el ends here
