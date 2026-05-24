;; -*- lexical-binding: t -*-
;;; init-company.el --- Company configuration

(require 'my-toggle-code-intelligence)

(use-package company
  :ensure t
  :demand t
  :hook
  (after-init . global-company-mode)
  (before-save . company-cancel)
  :config
  ;; company-mode settings
  (setq company-dabbrev-downcase nil
        ;; company-backends '((company-capf company-keywords company-files company-dabbrev))
        company-backends '((company-capf company-keywords company-files))
        ;; Visual tuning
        company-format-margin-function #'company-text-icons-margin
        company-text-icons-add-background t
        company-tooltip-margin 2
        company-tooltip-minimum-width 40
        company-tooltip-maximum-width 80
        company-tooltip-limit 12
        company-tooltip-align-annotations t
        company-tooltip-flip-when-above t
        )

  ;; Fill the gaps the theme leaves: only company-tooltip is themed.
  (with-eval-after-load 'company
    (let* ((bg (face-background 'company-tooltip nil t))
           (fg (face-foreground 'company-tooltip nil t))
           (sel-bg "#3E4451")
           (common "#61AFEF")
           (anno   "#7F848E"))
      (custom-set-faces
       `(company-tooltip-selection            ((t (:background ,sel-bg :foreground ,fg :weight semi-bold))))
       `(company-tooltip-common               ((t (:foreground ,common :weight bold))))
       `(company-tooltip-common-selection     ((t (:foreground ,common :weight bold))))
       `(company-tooltip-annotation           ((t (:foreground ,anno :slant normal))))
       `(company-tooltip-annotation-selection ((t (:foreground ,anno :slant normal :weight semi-bold))))
       `(company-tooltip-scrollbar-track      ((t (:background ,bg))))
       `(company-tooltip-scrollbar-thumb      ((t (:background ,sel-bg)))))))
  )

(use-package company-posframe
  :ensure t
  :after company
  :demand t
  :config
  (company-posframe-mode 1)

  ;; Posframe settings
  (setq company-tooltip-scrollbar-width 0
        company-posframe-show-params (list
                                      :internal-border-width 1
                                      :internal-border-color "#3E4451"
                                      :left-fringe 8
                                      :right-fringe 8
                                      :line-height 1.1))
  ;; Make the internal border actually render with the chosen color in GUI frames.
  (set-face-background 'internal-border "#3E4451")

  ;; Key bindings for company-active-map
  (define-key company-active-map (kbd "<TAB>") #'company-select-next-if-tooltip-visible-or-complete-selection)
  (define-key company-active-map (kbd "<backtab>") #'company-select-previous-or-abort)
  (define-key company-active-map (kbd "RET") #'company-complete-selection)

  ;; Patch function for posframe bug fix
  (defun company-select-next-if-tooltip-visible-or-complete-selection ()
    "Select next candidate if tooltip visible, otherwise complete selection."
    (interactive)
    (if (and t (> company-candidates-length 1))
        (call-interactively 'company-select-next)
      (call-interactively 'company-complete-selection)))

  ;; Key bindings for posframe-active-map
  (define-key company-posframe-active-map (kbd "<TAB>") #'company-select-next-if-tooltip-visible-or-complete-selection)
  (define-key company-posframe-active-map (kbd "<backtab>") #'company-select-previous-or-abort)
  (define-key company-posframe-active-map (kbd "RET") #'company-complete-selection)

  ;; Hooks for eglot highlight management
  (add-hook 'company-completion-started-hook   #'my-disable-eglot-highlight)
  (add-hook 'company-completion-finished-hook  #'my-enable-eglot-highlight)
  (add-hook 'company-completion-cancelled-hook #'my-enable-eglot-highlight)

  ;; Global yasnippet binding
  (global-set-key (kbd "s-r") #'company-yasnippet))

(use-package company-prescient
  :ensure t
  :after company
  :demand t
  :config
  (company-prescient-mode 1))

(provide 'init-company)

;;; init-company.el ends here
