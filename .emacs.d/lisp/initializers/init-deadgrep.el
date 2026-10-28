;;; -*- lexical-binding: t -*-
(declare-function deadgrep-mode "deadgrep")
(declare-function deadgrep-visit-result-other-window "deadgrep")

(defun my-deadgrep-edit-enter ()
  (interactive)
  (my-disable-code-intelligence)
  (refresh-current-mode))


(defun my-deadgrep-edit-exit ()
  (interactive)
  (my-enable-code-intelligence)
  (refresh-current-mode)
  (deadgrep-mode))

(defun my-deadgrep-visit-result-other-window-and-select ()
  (interactive)
  (deadgrep-visit-result-other-window)
  (other-window 1))

;; deadgrep-edit 修改并保存文件时，不要删除行尾空白
(defun my-deadgrep--keep-trailing-whitespace (orig-fun &rest args)
  (cl-letf (((symbol-function 'delete-trailing-whitespace-if-possible) #'ignore))
    (apply orig-fun args)))

(defun my-deadgrep--include-args (rg-args)
  (push "--hidden" rg-args) ;; consider hidden folders/files
  (push "--follow" rg-args) ;; follow symlink
  (push "--glob=!.git" rg-args))


(use-package deadgrep
  :ensure t
  :config
  (setq-default deadgrep--context (cons 2 2))
  (setq-default deadgrep-max-line-length 2000)
  :bind
  ( ;; ("C-c g" . deadgrep)
   :map
   deadgrep-mode-map
   ("RET" . deadgrep-visit-result)
   ("o" . deadgrep-visit-result-other-window)
   ("v" . my-deadgrep-visit-result-other-window-and-select)
   ("S" . deadgrep-search-term)
   ("D" . deadgrep-directory)
   ("g" . deadgrep-restart)
   ("n" . deadgrep-forward-match)
   ("r" . deadgrep-backward-match)
   ("p" . deadgrep-backward-match)
   ("N" . deadgrep-forward-filename)
   ("P" . deadgrep-backward-filename)
   ("C-c C-q" . deadgrep-edit-mode)
   :map
   deadgrep-edit-mode-map
   ("C-c C-c" . my-deadgrep-edit-exit))
  :hook (deadgrep-edit-mode . my-deadgrep-edit-enter)
  :init
  (advice-add 'deadgrep-visit-result :after #'xref-pulse-momentarily)
  (advice-add 'deadgrep-visit-result :after #'my-quit-other-window)
  (advice-add 'deadgrep-visit-result-other-window :after #'xref-pulse-momentarily)
  (advice-add 'deadgrep-edit-mode :after #'xref-pulse-momentarily)
  (advice-add 'deadgrep--arguments :filter-return #'my-deadgrep--include-args)
  (advice-add 'deadgrep--propagate-change :around #'my-deadgrep--keep-trailing-whitespace)
  (add-hook 'deadgrep-finished-hook #'my-quit-other-window)
  ;; Face configuration moved to custom-set-faces
  )


(provide 'init-deadgrep)
