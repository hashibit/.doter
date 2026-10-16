;; -*- lexical-binding: t -*-
;;; init-company.el --- Company configuration

(require 'my-toggle-code-intelligence)

(defvar company-dabbrev-downcase)

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
  (let* ((bg (face-background 'company-tooltip nil t))
         (fg (face-foreground 'company-tooltip nil t))
         (sel-bg "#3E4451")
         (common "#61AFEF")
         (anno   "#7F848E"))
    (pcase-dolist (`(,face . ,attrs)
                   `((company-tooltip-selection            :background ,sel-bg :foreground ,fg :weight normal)
                     (company-tooltip-common               :foreground ,common :weight normal)
                     (company-tooltip-common-selection     :foreground ,common :weight normal)
                     (company-tooltip-annotation           :foreground ,anno :slant normal :weight normal)
                     (company-tooltip-annotation-selection :foreground ,anno :slant normal :weight normal)
                     (company-tooltip-scrollbar-track      :background ,bg)
                     (company-tooltip-scrollbar-thumb      :background ,sel-bg)))
      (face-spec-set face `((t ,@attrs)) 'face-override-spec)))
  )

(defvar company-candidates-length)

;; Patch function for posframe bug fix
;; (company's own `company-select-next-if-tooltip-visible-or-complete-selection'
;; checks tooltip visibility, which is always false with company-posframe)
(defun my-company-select-next-or-complete-selection ()
  "Select next candidate if there are several, otherwise complete selection."
  (interactive)
  (if (> company-candidates-length 1)
      (call-interactively #'company-select-next)
    (call-interactively #'company-complete-selection)))

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
  ;; Color the child-frame border (Emacs 28+). This face only affects posframes,
  ;; not the main Emacs frame's internal border.
  (when (facep 'child-frame-border)
    (set-face-background 'child-frame-border "#3E4451"))


  ;; Key bindings for company-active-map
  (keymap-set company-active-map "<TAB>" #'my-company-select-next-or-complete-selection)
  (keymap-set company-active-map "<backtab>" #'company-select-previous-or-abort)
  (keymap-set company-active-map "RET" #'company-complete-selection)

  ;; Key bindings for posframe-active-map
  (keymap-set company-posframe-active-map "<TAB>" #'my-company-select-next-or-complete-selection)
  (keymap-set company-posframe-active-map "<backtab>" #'company-select-previous-or-abort)
  (keymap-set company-posframe-active-map "RET" #'company-complete-selection)

  ;; Hooks for eglot highlight management
  (add-hook 'company-completion-started-hook   #'my-disable-eglot-highlight)
  (add-hook 'company-completion-finished-hook  #'my-enable-eglot-highlight)
  (add-hook 'company-completion-cancelled-hook #'my-enable-eglot-highlight)

  ;; Global yasnippet binding
  (keymap-global-set "s-r" #'company-yasnippet))

(use-package company-prescient
  :ensure t
  :after company
  :demand t
  :config
  (company-prescient-mode 1)
  ;; Kill the bold weight on matched characters; keep just the color/underline cues.
  (with-eval-after-load 'prescient
    (set-face-attribute 'prescient-primary-highlight   nil :weight 'normal)
    (set-face-attribute 'prescient-secondary-highlight nil :weight 'normal)))

(provide 'init-company)

;;; init-company.el ends here
