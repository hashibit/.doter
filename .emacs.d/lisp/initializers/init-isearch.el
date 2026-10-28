;; -*- lexical-binding: t -*-
;;; init-isearch.el --- Isearch Configuration

;;; Commentary:
;;
;;  Isearch hooks: code intelligence, cursor color, match highlight
;;

;;; Code:

(require 'my-toggle-code-intelligence)

(add-hook 'isearch-mode-hook #'my-disable-code-intelligence)
(add-hook 'isearch-mode-end-hook #'my-enable-code-intelligence)

(defun my-change-cursor-type-when-isearch ()
  (interactive)
  (if (bound-and-true-p isearch-mode)
      (progn
        (setq cursor-type 'bar)
        (set-cursor-color "yellow"))
    (progn
      (setq cursor-type 'box)
      (set-cursor-color "red"))))
(add-hook 'isearch-mode-hook #'my-change-cursor-type-when-isearch)
(add-hook 'isearch-mode-end-hook #'my-change-cursor-type-when-isearch)

;; Safe isearch 全局高亮
(require 'my-isearch-highlight-all)
(add-hook 'isearch-update-post-hook #'my-isearch-highlight-all-matches)
(add-hook 'isearch-mode-end-hook #'my-isearch-cleanup)

(provide 'init-isearch)

;;; init-isearch.el ends here
