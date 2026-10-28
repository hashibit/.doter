;; -*- lexical-binding: t -*-
;;; init-xwidget.el --- Xwidget Webkit Configuration

;;; Commentary:
;;
;;  Web search and xwidget-webkit browsing
;;

;;; Code:

(defun my-web-search ()
  "在默认浏览器 (Chrome) 中 Google 搜索"
  (interactive)
  (let ((query (read-string "Search: ")))
    (browse-url (concat "https://www.google.com/search?q="
                        (url-hexify-string query)))))
(bind-key "C-c w s" #'my-web-search)

(defun my-xwidget-webkit-search ()
  "搜索功能"
  (interactive)
  (let ((query (read-string "Search: ")))
    (xwidget-webkit-browse-url (concat "https://www.google.com/search?q="
                                       (url-hexify-string query)))))

;; Old names, so M-x my/... still works.
(define-obsolete-function-alias 'my/web-search #'my-web-search "2026-10-27")
(define-obsolete-function-alias 'my/xwidget-webkit-search #'my-xwidget-webkit-search "2026-10-27")

(use-package xwidget
  :ensure nil
  ;; xwidget-webkit 会吞掉 ESC 键，改用 my-web-search
  ;; :bind (("C-c w s" . my-xwidget-webkit-search))
  :bind (:map xwidget-webkit-mode-map
              ("r" . xwidget-webkit-reload)
              ("L" . xwidget-webkit-back)
              ("H" . xwidget-webkit-forward)
              ("j" . xwidget-webkit-scroll-up-line)
              ("k" . xwidget-webkit-scroll-down-line)
              ("+" . xwidget-webkit-zoom-in)
              ("-" . xwidget-webkit-zoom-out)
              ;; 添加复制粘贴绑定
              ("s-c" . xwidget-webkit-copy-selection-as-kill)
              ("s-v" . xwidget-webkit-paste)
              ("s-a" . xwidget-webkit-select-all)          ; Cmd+A 全选
              ("s-r" . xwidget-webkit-reload)              ; Cmd+R 刷新
              ("s-l" . xwidget-webkit-current-url)))

(use-package xwwp
  :ensure t
  :bind (("C-c w o" . xwwp))
  :custom
  (xwwp-follow-link-completion-system 'ivy)
  :bind (:map xwidget-webkit-mode-map
              ("v" . xwwp-follow-link)))

(provide 'init-xwidget)

;;; init-xwidget.el ends here
