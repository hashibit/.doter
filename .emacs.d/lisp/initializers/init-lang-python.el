;; -*- lexical-binding: t -*-
;;; init-lang-python.el --- Python language configuration

(defun my-python-mode-hook()
  "Hook for Python mode configuration."
  ;; Python-specific configuration can be added here
  (setq tab-width 4)
  )

(add-hook 'python-ts-mode-hook #'my-python-mode-hook)

;; (use-package poetry
;;   :ensure t
;;   :defer t
;;   :config
;;   ;; Checks for the correct virtualenv. Better strategy IMO because the default
;;   ;; one is quite slow.
;;   (setq poetry-tracking-strategy 'switch-buffer)
;;   :hook (python-ts-mode . poetry-tracking-mode)
;;   )

(provide 'init-lang-python)

;;; init-lang-python.el ends here
