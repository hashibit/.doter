;;; -*- lexical-binding: t -*-
;; Taken from https://andreyor.st/posts/2020-05-10-making-emacs-tabs-look-like-in-atom/
;; https://github.com/andreyorst/dotfiles/blob/740d346088ce5a51804724659a895d13ed574f81/.config/emacs/README.org#tabline

(require 'seq)

(defvar my-tab-line-face-height 140)
(defvar default-font-family)
(declare-function my-god-this-is-normal-editor-buffer "init-god")
(declare-function tab-line-tabs-window-buffers "tab-line")
(declare-function tab-line-tabs-buffer-groups "tab-line")

(defcustom my-tab-line-tab-min-width 20
  "Minimum width of a tab in characters."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line-tab-max-width 30
  "Maximum width of a tab in characters."
  :type 'integer
  :group 'tab-line)

(defun my/set-tab-theme ()
  (let ((bg (face-attribute 'mode-line :background))
         (fg (face-attribute 'default :foreground))
         (_hg (face-attribute 'default :background))
         (hi-bg "#FFC44C")
         (hl-bg "#FFDB93")
         (modified-fg "red")
         (base (face-attribute 'mode-line :background))
         (box-width (/ (line-pixel-height) 4))
         (family (or (bound-and-true-p default-font-family) 'unspecified)))
    (set-face-attribute 'tab-line nil
      :background 'unspecified :foreground 'unspecified
      :family family
      :height 0.8
      :inherit 'default
      :box nil ;; (list :line-width -1 :color base)
      )
    (set-face-attribute 'tab-line-tab-modified nil
      :foreground modified-fg
      )
    (set-face-attribute 'tab-line-tab nil
      :foreground fg :background bg
      :family family :height my-tab-line-face-height
      :weight 'normal
      :inherit nil
      :box (list :line-width box-width :color bg))
    (set-face-attribute 'tab-line-tab-inactive nil
      :foreground fg :background base
      :family family :height my-tab-line-face-height
      :weight 'normal
      :inherit nil
      :box (list :line-width box-width :color base))
    (set-face-attribute 'tab-line-highlight nil
      :foreground "black" :background hl-bg
      :family family :height my-tab-line-face-height
      :weight 'normal
      :inherit nil
      :box (list :line-width box-width :color hl-bg))
    (set-face-attribute 'tab-line-tab-current nil
      :foreground "black" :background hi-bg
      :family family :height my-tab-line-face-height
      :weight 'normal
      :inherit nil
      :box (list :line-width box-width :color hi-bg))))

(defun my/tab-line-name-buffer (buffer &rest _buffers)
  "Create name for tab with padding and truncation.
If buffer name is shorter than `my-tab-line-tab-max-width' it gets
centered with spaces, otherwise it is truncated, to preserve
equal width for all tabs.  This function also tries to fit as
many tabs in window as possible, so if there are no room for tabs
with maximum width, it calculates new width for each tab and
truncates text if needed.  Minimal width can be set with
`my-tab-line-tab-min-width' variable."
  (with-current-buffer buffer
    (let* ((window-width (window-width (get-buffer-window)))
           (tab-amount (length (tab-line-tabs-window-buffers)))
           (window-max-tab-width (if (>= (* (+ my-tab-line-tab-max-width 3) tab-amount) window-width)
                                     (/ window-width tab-amount)
                                   my-tab-line-tab-max-width))
           (tab-width (- (cond ((> window-max-tab-width my-tab-line-tab-max-width)
                                my-tab-line-tab-max-width)
                               ((< window-max-tab-width my-tab-line-tab-min-width)
                                my-tab-line-tab-min-width)
                               (t window-max-tab-width))
                         3)) ;; compensation for ' x ' button
           (buffer-name (string-trim (buffer-name)))
           (name-width (length buffer-name)))
      (if (>= name-width tab-width)
          (concat  " " (truncate-string-to-width buffer-name (- tab-width 2)) "…")
        (let* ((padding (make-string (+ (/ (- tab-width name-width) 2) 1) ?\s))
               (buffer-name (concat padding buffer-name)))
          (concat buffer-name (make-string (- tab-width (length buffer-name)) ?\s)))))))

(defun my/tab-line-close-tab (tab)
  "Close TAB, used as `tab-line-close-tab-function'.
If tab is presented in another window, close the tab by using
`bury-buffer` function.  If tab is unique to all existing
windows, kill the buffer with `kill-buffer` function.  Lastly, if
no tabs left in the window, it is deleted with `delete-window`
function."
  (let* ((window (selected-window))
         (buffer (if (bufferp tab) tab (cdr (assq 'buffer tab))))
         (tab-list (tab-line-tabs-window-buffers))
         (buffer-list (flatten-list
                        (mapcar (lambda (w)
                                  (with-selected-window w
                                    (tab-line-tabs-window-buffers)))
                          (window-list)))))
    (if (> (seq-count (lambda (b) (eq b buffer)) buffer-list) 1)
        (progn
          (if (eq buffer (current-buffer))
              (bury-buffer)
            (set-window-prev-buffers window (assq-delete-all buffer (window-prev-buffers)))
            (set-window-next-buffers window (delq buffer (window-next-buffers))))
          (unless (cdr tab-list)
            (ignore-errors (delete-window window))))
      (and (kill-buffer buffer)
           (unless (cdr tab-list)
             (ignore-errors (delete-window window)))))))

(use-package tab-line
  :ensure nil
  :hook (after-init . global-tab-line-mode)
  :bind
  ("s-h" . tab-line-switch-to-prev-tab)
  ("s-l" . tab-line-switch-to-next-tab)
  ("s-t" . tab-line-new-tab)
  ("s-w" . kill-current-buffer)
  :config
  (setq tab-line-close-button-show t
    tab-line-close-tab-function #'my/tab-line-close-tab
    tab-line-new-button-show nil
    tab-line-separator ""
    tab-line-tab-name-function #'my/tab-line-name-buffer
    tab-line-right-button (propertize (if (char-displayable-p ?▶) " ▶ " " > ")
                            'keymap tab-line-right-map
                            'mouse-face 'tab-line-highlight
                            'help-echo "Click to scroll right")
    tab-line-left-button (propertize (if (char-displayable-p ?◀) " ◀ " " < ")
                           'keymap tab-line-left-map
                           'mouse-face 'tab-line-highlight
                           'help-echo "Click to scroll left")
    tab-line-close-button (propertize (if (char-displayable-p ?×) " × " " x ")
                            'keymap tab-line-tab-close-map
                            'mouse-face 'tab-line-close-highlight
                            'help-echo "Click to close tab"))

  (my/set-tab-theme)

  ;;(dolist (mode '(ediff-mode process-menu-mode term-mode vterm-mode))
  ;;(add-to-list 'tab-line-exclude-modes mode))
  ;; (dolist (mode '(ediff-mode process-menu-mode dired-mode dashboard-mode eshell-mode slime-repl-mode inferior-emacs-lisp-mode comint-mode
  ;;                            help-mode Custom-mode deadgrep-mode lisp-interaction-mode
  ;;                            special-mode compilation-mode fundamental-mode xref--xref-buffer-mode
  ;;                            ))
  ;;   (add-to-list 'tab-line-exclude-modes mode))

  (dolist (mode '(ediff-mode process-menu-mode))
    (add-to-list 'tab-line-exclude-modes mode))

  (setq tab-line-tabs-buffer-group-function #'my-editor-group)
  (setq tab-line-tabs-buffer-group-sort-function #'buffer-comp-less-p)
  (setq tab-line-tabs-function #'tab-line-tabs-buffer-groups)
  )


;; sort tabs
;;

(defun my-editor-group(buf)
  (let ((bufname (buffer-name buf)))
    (if (my-god-this-is-normal-editor-buffer bufname) "> " nil)))

(defun buffer-comp-less-p(buf1 buf2)
  (let ((name1 (buffer-name buf1))
        (name2 (buffer-name buf2)))
    (string< name1 name2)))

;; (setq my/current-tab-list (list (current-buffer)))
;; (setq tab-line-tabs-function 'tab-line-tabs-mode-buffers)
;; (defun tab-line-tabs-mode-buffers ()
;;   my/current-tab-list)
;;
;; (defun my/add-current-buffer-to-tab ()
;;   (interactive)
;;   (setq my/current-tab-list (add-to-list 'my/current-tab-list (current-buffer)))
;;   )
;; (add-hook 'find-file-hook 'my/add-current-buffer-to-tab)
;; (add-hook 'dired-mode-hook 'my/add-current-buffer-to-tab)
;;
;; (defun my/close-tab ()
;;   (interactive)
;;   (setq my/current-tab-list (delete (current-buffer) my/current-tab-list))
;;   (kill-buffer)
;;   )
;;
;; (defun my/drop-tab ()
;;   (interactive)
;;   (setq my/current-tab-list (delete (current-buffer) my/current-tab-list))
;;   (switch-to-buffer (nth 0 my/current-tab-list))
;;   )
;;
;; (global-tab-line-mode t)

(provide 'init-tabline)
