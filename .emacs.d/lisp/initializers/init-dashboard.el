;; -*- lexical-binding: t -*-
;;; init-dashboard.el --- Dashboard configuration

;; use-package with package.el:

;;; Code:

(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook))

;; (use-package dashboard-hackernews)



(provide 'init-dashboard)

;;; init-dashboard.el ends here
