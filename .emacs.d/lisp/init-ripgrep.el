;; -*- lexical-binding: t -*-
;;; init-ripgrep.el --- Ripgrep Configuration

;;; Commentary:
;;
;;  Fast grep tool configuration
;;

;;; Code:

(declare-function ripgrep/kill-buffer "ripgrep")

(defun my-ripgrep-kill-buffer()
  (interactive)
  ;; ripgrep 包已停用 (见下方注释)，没有该函数时直接 kill 当前 buffer
  (if (fboundp 'ripgrep/kill-buffer)
      (ripgrep/kill-buffer)
    (kill-buffer))
  (delete-window))


;;; rg.el
(use-package rg
  :ensure nil
  :bind
  (
    ("C-c g" . rg)
    )
  :config
  (setq rg-command-line-flags '("--context" "2"))
  (setq rg-show-header nil)


  (defun my-disable-my-special-buffer-keys (&rest _r)
    (my-change-buffer-name-from-special-to-legendary (buffer-name))
    (my-special-buffer-keys-minor-mode 0))

  (defun my-enable-my-special-buffer-keys (&rest _r)
    (my-change-buffer-name-from-legendary-to-special (buffer-name))
    (my-special-buffer-keys-minor-mode 1))


  ;; 已停用：原来 advice-add 之后紧接着 advice-remove，实际从未生效。
  ;; 需要时取消注释，在 wgrep 编辑期间关闭 special buffer 按键。
  ;; (advice-add 'wgrep-change-to-wgrep-mode :after #'my-disable-my-special-buffer-keys)
  ;; (advice-add 'wgrep-finish-edit :after #'my-enable-my-special-buffer-keys)

  )



; (use-package ripgrep
;   :ensure t
;   :config
;   ;; Face configuration moved to custom-set-faces
;   :bind
;   (:map ripgrep-search-mode-map
;         (";" . scroll-up-command)
;         ("'" . scroll-down-command)
;         ("k" . previous-line)
;         ("j" . next-line)
;         ("x" . my-ripgrep-kill-buffer)))

(provide 'init-ripgrep)

;;; init-ripgrep.el ends here
