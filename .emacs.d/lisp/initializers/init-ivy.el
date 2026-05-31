;; -*- lexical-binding: t -*-
;;; init-ivy.el --- Ivy configuration

(use-package ivy
  :ensure t
  :diminish (ivy-mode . "")
  :bind
  ((:map ivy-minibuffer-map
         ("TAB" . ivy-next-line)
         ("<backtab>" . ivy-previous-line)
         ("<escape>" . keyboard-escape-quit)))
  :config
  (ivy-mode 1)

  ;; don't sort mark ring
  (ivy-configure 'counsel-mark-ring :sort-fn #'ignore)

  ;; add 'recentf-mode' and bookmarks to 'ivy-switch-buffer'.
  (setq counsel-switch-buffer-preview-virtual-buffers nil
        ivy-use-virtual-buffers t
        ivy-height 10               ; number of result lines to display
        ivy-count-format ""         ; does not count candidates
        ivy-initial-inputs-alist nil ; no regexp by default
        ;; configure regexp engine - allow input not in order
        ivy-re-builders-alist '((t . ivy--regex-ignore-order)))

  ;; don't show these buffers in counsel-switch-buffer
  (dolist (buffer '("\\*Messages\\*"
                    "\\*Help\\*"
                    "\\*Warnings\\*"
                    "\\*Compile-Log\\*"
                    "\\*EGLOT"
                    "\\*rdm\\*"
                    "\\*claude"
                    "\\*Backtrace\\*"
                    "\\*ripgrep-search\\*"
                    "\\*eat\\*"
                    "\\*eat"
                    "\\*markdown-output*"
                    "\\*Ilist"
                    "\\*Shell"
                    "\\*rg"
                    "\\*Occur"
                    "\\*dashboard\\*"
                    "\\*xref\\*"
                    "\\*xwidget-webkit"
                    "\\*deadgrep"
                    "\\*format-all-errors"
                    "\\*Native-compile-Log"
                    "\\*Customize"
                    "\\*Semantic"
                    "\\*Flymake"
                    "\\*Ibuffer\\*"))
    (add-to-list 'ivy-ignore-buffers buffer)))

(use-package ivy-posframe
  :ensure t
  :after ivy
  :config
  (defun ivy-format-function-default (cands)
    "Transform CANDS into a string for minibuffer."
    (concat
     (propertize
      (format "%s\n" (make-string (round (* .50 (frame-width))) ?─))
      'face '(:foreground "#06C668"))
     (ivy--format-function-generic
      (lambda (str)
        (concat " > " (ivy--add-face str 'ivy-current-match) ""))
      (lambda (str) (concat "   " str ""))
      cands "\n")
     "\n"))

  (defun my-ivy-posframe-get-size ()
    "Set the ivy-posframe size according to the current frame."
    (let ((height (or ivy-posframe-height (or (+ ivy-height 2) 20)))
          (width (or ivy-posframe-width (round (* .50 (frame-width))))))
      (list :height height :min-height height :min-width width)))

  ;; Configuration
  (setq ivy-posframe-size-function 'my-ivy-posframe-get-size
        ivy-posframe-display-functions-alist '((t . ivy-posframe-display-at-window-bottom-left))
        ivy-posframe-border-width my-posframe-border-width
        ivy-posframe-parameters `((left-fringe . ,my-posframe-fringe-width)
                                  (right-fringe . ,my-posframe-fringe-width)))

  ;; 安全地设置 posframe 的 face 属性
  (with-eval-after-load 'ivy-posframe
    (set-face-attribute 'ivy-posframe nil :background "black")
    (set-face-attribute 'ivy-posframe-border nil :background "#353535"))

  (ivy-posframe-mode 1))

(provide 'init-ivy)

;;; init-ivy.el ends here
