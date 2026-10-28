;; -*- lexical-binding: t -*-
;;; init-neotree.el --- Neotree configuration

;;; Code:

(defvar neo-window-width)


(defun my-neotree-window-narrow ()
  "Make the neotree window 25 columns wide."
  (interactive)
  (setq neo-window-width 25)
  (neo-window--zoom 'minimize) ;; private method here.
  )

(defun my-neotree-window-enlarge ()
  "Make the neotree window a quarter of the frame wide."
  (interactive)
  (setq neo-window-width (/ (frame-width) 4))
  (neo-window--zoom 'minimize) ;; private method here.
  )


(defun my-darker-background-for-sidebar ()
  (face-remap-add-relative 'default :background "#1E2127"))

(use-package neotree
  :ensure t
  :init
  (setq neo-theme 'nerd)
  ;; (setq neo-auto-indent-point 't)
  (setq neo-confirm-create-file 'off-p)
  (setq neo-confirm-create-directory 'off-p)
  (setq neo-smart-open t)
  (setq neo-window-fixed-size nil)
  (setq neo-show-hidden-files t)
  ;; (add-hook 'neotree-mode-hook #'my-darker-background-for-sidebar)
  ;; (setq neo-window-width (/ (display-pixel-width) 4))
  ;; (setq neo-window-width 45)
  ;; (setq neo-toggle-window-keep-p 't)
  :hook (neotree-mode . my-special-buffer-keys-minor-mode)
  :bind
  (:map
   neotree-mode-map
   ("L" . my-neotree-window-enlarge)
   ("H" . my-neotree-window-narrow)
   ("u" . neotree-select-up-node)
   ("f" . neotree-hidden-file-toggle)
   ("c n" . neotree-create-node)
   ("a" . neotree-create-node)))



(defun my-neotree-project-dir ()
  "Open NeoTree using the git root."
  (interactive)
  (let
      (
       (project-dir (projectile-project-root))
       (file-name (buffer-file-name)))
    (neotree-toggle)
    (if project-dir
        (when (neo-global--window-exists-p)
          (neotree-dir project-dir)
          (neotree-find file-name))
      (message "Could not find git project root."))))

(defun my-neotree-toggle ()
  "Show neotree, or show the project root when it is open."
  (interactive)
  (if
      (and (fboundp 'neo-global--window-exists-p)
           (neo-global--window-exists-p))
      (my-neotree-project-dir)
    (neotree-show)))

(defun my-neotree-find ()
  "Show the current file in neotree."
  (interactive)
  (unless (fboundp 'neo-global--window-exists-p)
    (neotree-show))
  (unless (neo-global--window-exists-p)
    (neotree-show))
  (neotree-find))




(defun my-add-padding-for-neotree ()
  (set-window-margins (get-buffer-window " *NeoTree*" 'visible) 1))
(advice-add 'neotree-show :after #'my-add-padding-for-neotree)


(provide 'init-neotree)

;;; init-neotree.el ends here
