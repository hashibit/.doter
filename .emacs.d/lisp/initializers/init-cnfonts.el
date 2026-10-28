;; -*- lexical-binding: t -*-
;;; init-cnfonts.el --- Chinese Font Configuration

;;; Commentary:
;;
;;  Chinese and emoji font setup with cnfonts
;;

;;; Code:

(require 'cnfonts)
;; 让 cnfonts 在 Emacs 启动时自动生效。
(cnfonts-mode 1)
;; 添加两个字号增大缩小的快捷键
;; (define-key cnfonts-mode-map (kbd "C--") #'cnfonts-decrease-fontsize)
;; (define-key cnfonts-mode-map (kbd "C-=") #'cnfonts-increase-fontsize)
(setopt cnfonts-use-system-type t)
(setopt cnfonts-personal-fontnames '(("IBM Plex Mono") ("IBM Plex Sans SC" "PingFang SC" "等距更纱黑体 SC") ("Symbola") ("Apple Color Emoji")))

;; Emoji 字体调小一点
(when (member "Apple Color Emoji" (font-family-list))
  (set-fontset-font "fontset-default"
                    'unicode
                    (font-spec :family "Apple Color Emoji" :size 12)
                    nil 'append))

(provide 'init-cnfonts)

;;; init-cnfonts.el ends here
