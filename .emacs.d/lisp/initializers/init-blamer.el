;;; -*- lexical-binding: t -*-


(use-package blamer
  :bind (("s-i" . blamer-show-commit-info)
          ("C-c i" . blamer-show-posframe-commit-info))
  :defer 20
  :custom
  (blamer-idle-time 0.3)
  (blamer-min-offset 70)
  :custom-face
  (blamer-face ((t :foreground "#7a88cf"
                  :background "#161c23"
                  :height 140
                  :italic t)))
  ;; :config
  ;; (global-blamer-mode 1)
  )



(provide 'init-blamer)
