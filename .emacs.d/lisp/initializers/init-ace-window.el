;;; -*- lexical-binding: t -*-

(use-package ace-window
  :ensure t
  ;; must ensure, treemacs depend on it
  ;; load at startup: ace-window-display-mode should be on from the start
  :demand t
  :delight
  :config
  (ace-window-display-mode 1)
  (setq aw-keys '(?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9 ?0))
  :bind (("M-o" . ace-window)))

;; alternatively, use Meta-<left> Meta-<right> to move cursor to window
;; for iTerms2 user, disable alt-> alt-< to send alt-f alt-b in `profile->keys`
(windmove-default-keybindings 'meta)


(provide 'init-ace-window)
