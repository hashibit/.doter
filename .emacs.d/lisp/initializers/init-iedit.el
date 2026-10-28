;; -*- lexical-binding: t -*-
;;; init-iedit.el --- Iedit Configuration

;;; Commentary:
;;
;;  Multiple editing functionality
;;

;;; Code:

(use-package iedit
  :ensure t
  :bind (("C-M-'" . iedit-mode))
  :config
  ;; Face configuration moved to custom-set-faces
  )

(provide 'init-iedit)

;;; init-iedit.el ends here