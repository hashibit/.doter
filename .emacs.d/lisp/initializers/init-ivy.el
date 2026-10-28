;; -*- lexical-binding: t -*-
;;; init-ivy.el --- Ivy configuration

;;; Code:

(defvar counsel-switch-buffer-preview-virtual-buffers)
(defvar my-posframe-border-width)
(defvar my-posframe-fringe-width)

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
                    "\\*floating-eat"
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

(defvar ivy-height)
(defvar ivy-posframe-height)
(defvar ivy-posframe-width)
(declare-function ivy--format-function-generic "ivy")
(declare-function ivy--add-face "ivy")

(defun my-ivy--format-current (str)
  (concat " > " (ivy--add-face str 'ivy-current-match)))

(defun my-ivy--format-other (str)
  (concat "   " str))

(defun my-ivy-format-function (cands)
  "Transform CANDS into a string for minibuffer."
  (concat
   (propertize
    (format "%s\n" (make-string (round (* .50 (frame-width))) ?─))
    'face '(:foreground "#06C668"))
   (ivy--format-function-generic
    #'my-ivy--format-current #'my-ivy--format-other cands "\n")
   "\n"))

(defun my-ivy-posframe-get-size ()
  "Set the ivy-posframe size according to the current frame."
  (let ((height (or ivy-posframe-height (+ ivy-height 2)))
        (width (or ivy-posframe-width (round (* .50 (frame-width))))))
    (list :height height :min-height height :min-width width)))

(use-package ivy-posframe
  :ensure t
  :after ivy
  :config
  (setf (alist-get t ivy-format-functions-alist) #'my-ivy-format-function)

  ;; Configuration
  (setq ivy-posframe-size-function 'my-ivy-posframe-get-size
        ivy-posframe-display-functions-alist '((t . ivy-posframe-display-at-window-bottom-left))
        ivy-posframe-border-width my-posframe-border-width
        ivy-posframe-parameters `((left-fringe . ,my-posframe-fringe-width)
                                  (right-fringe . ,my-posframe-fringe-width)))

  (set-face-attribute 'ivy-posframe nil :background "black")
  (set-face-attribute 'ivy-posframe-border nil :background "#353535")

  (ivy-posframe-mode 1))

(provide 'init-ivy)

;;; init-ivy.el ends here
