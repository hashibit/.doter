;;; -*- lexical-binding: t -*-

(declare-function centaur-tabs-view "centaur-tabs-functions")
(declare-function centaur-tabs-current-tabset "centaur-tabs-functions")
(declare-function centaur-tabs-buffer-select-tab "centaur-tabs-functions")

(defun my-centaur-select-tab (n)
  (interactive "p")
  (let* ((tabs-view (centaur-tabs-view (centaur-tabs-current-tabset t)))
          (tabs-count (length tabs-view))
          (n
            (if (> tabs-count n)
              n
              tabs-count))
          (n (- n 1))
          (tab (nth n tabs-view)))
    (centaur-tabs-buffer-select-tab tab)
    ;; (message "n %d, tabs-view:%s, tab: %s" n tabs-view tab)
    ))

(defmacro def-centaur-select-tab-funs (numbers)
  `(progn
     ,@(mapcar
        (lambda (number)
          `(defun ,(intern (format "my-centaur-select-tab-%s" number)) ()
             (interactive)
             (my-centaur-select-tab ,number)))
        numbers)))

(def-centaur-select-tab-funs (1 2 3 4 5 6 7 8 9))


;; have to set here!
(defvar centaur-tabs-bar-height 22)
(defvar centaur-tabs-height 22)
(setq centaur-tabs-bar-height 22
      centaur-tabs-height 22)

(use-package centaur-tabs
  :demand t
  :init (setq centaur-tabs-enable-key-bindings t)
  :config
  (setq
    ;; centaur-tabs-gray-out-icons 'buffer
    centaur-tabs-set-icons nil
    ;; centaur-tabs-icon-scale-factor 0.8
    centaur-tabs-set-modified-marker t
    centaur-tabs-modified-marker "*"
    centaur-tabs-set-close-button nil
    centaur-tabs-left-edge-margin " "
    centaur-tabs-right-edge-margin " "
    centaur-tabs-set-bar 'under
    x-underline-at-descent-line t
    centaur-tabs-show-jump-identifier nil)
  (centaur-tabs-headline-match)
  (centaur-tabs-mode t)
  (push "*scratch" centaur-tabs-excluded-prefixes)
  (push "*vc*" centaur-tabs-excluded-prefixes)
  (push "Treemacs" centaur-tabs-excluded-prefixes)
  (push "*grep" centaur-tabs-excluded-prefixes)
  (push "*deadgrep" centaur-tabs-excluded-prefixes)
  (push "*Messages" centaur-tabs-excluded-prefixes)
  (push "*Warnings" centaur-tabs-excluded-prefixes)
  (push "*Backtrace" centaur-tabs-excluded-prefixes)
  (push "*blink-search" centaur-tabs-excluded-prefixes)
  (push "*Gofmt" centaur-tabs-excluded-prefixes)
  (push "*Semantic" centaur-tabs-excluded-prefixes)
  (push "*Completion" centaur-tabs-excluded-prefixes)
  (push "*compilation" centaur-tabs-excluded-prefixes)
  (push "*Annotate" centaur-tabs-excluded-prefixes)
  (push "*vc-diff*" centaur-tabs-excluded-prefixes)
  (push "*Flymake" centaur-tabs-excluded-prefixes)
  (push "*slime" centaur-tabs-excluded-prefixes)
  (push "*inferior-lisp*" centaur-tabs-excluded-prefixes)
  (push "*Customize" centaur-tabs-excluded-prefixes)
  (push "*xref" centaur-tabs-excluded-prefixes)
  (push "*Async-native-compile-log" centaur-tabs-excluded-prefixes)
  (push "*EGLOT" centaur-tabs-excluded-prefixes)
  (push "*emacs" centaur-tabs-excluded-prefixes)
  (push "*Ilist*" centaur-tabs-excluded-prefixes)
  (push "*Occur*" centaur-tabs-excluded-prefixes)
  (push "*Ibuffer*" centaur-tabs-excluded-prefixes)
  (push "*hmoccur" centaur-tabs-excluded-prefixes)
  (push "*Ivy" centaur-tabs-excluded-prefixes)
  ;; (centaur-tabs-projectile-buffer-groups)
  ;; (defun centaur-tabs-buffer-groups ()
  ;;   ;; only one group
  ;;   (list "GROUP"))
  ;; ;; disable some mouse event
  (dolist (event '("mouse-3" "mouse-5" "mouse-4" "wheel-down" "wheel-up"))
    (keymap-set centaur-tabs-mode-map
                (format "<%s> <%s>" centaur-tabs-display-line event)
                #'ignore))
  :bind
  ("s-h" . centaur-tabs-backward)
  ("s-l" . centaur-tabs-forward)
  ("s-t" . centaur-tabs--create-new-tab)
  ;; ("s-n" . centaur-tabs--create-new-empty-buffer)
  ("s-w" . centaur-tabs--kill-this-buffer-dont-ask)
  ("s-1" . my-centaur-select-tab-1)
  ("s-2" . my-centaur-select-tab-2)
  ("s-3" . my-centaur-select-tab-3)
  ("s-4" . my-centaur-select-tab-4)
  ("s-5" . my-centaur-select-tab-5)
  ("s-6" . my-centaur-select-tab-6)
  ("s-7" . my-centaur-select-tab-7)
  ("s-8" . my-centaur-select-tab-8)
  ("s-9" . my-centaur-select-tab-9))

(with-eval-after-load 'centaur-tabs
  (dolist (face '(centaur-tabs-default
                   centaur-tabs-unselected
                   centaur-tabs-selected
                   centaur-tabs-unselected-modified
                   centaur-tabs-selected-modified
                   centaur-tabs-close-unselected
                   centaur-tabs-close-selected
                   centaur-tabs-name-mouse-face
                   centaur-tabs-close-mouse-face
                   centaur-tabs-modified-marker-selected
                   centaur-tabs-modified-marker-unselected
                   centaur-tabs-active-bar-face
                   centaur-tabs-jump-identifier-selected
                   centaur-tabs-jump-identifier-unselected
                   centaur-tabs-dim-buffer-face))
    (set-face-attribute face nil :weight 'normal :family "IBM Plex Mono" :height 140)
    )

  (set-face-attribute 'centaur-tabs-selected nil :inherit 'default :foreground "black" :background "#FFC44C" :weight 'normal)
  (set-face-attribute 'centaur-tabs-selected-modified        nil :inherit 'default :foreground "black" :background "#FCE094" :weight 'normal)
  (set-face-attribute 'centaur-tabs-modified-marker-selected nil :inherit 'default :foreground "black" :background "#FCE094" :weight 'normal)

  ;; ;; modified tab foreground
  ;; (set-face-foreground 'centaur-tabs-selected-modified "#61AFEF")
  ;; (set-face-foreground 'centaur-tabs-unselected-modified "#61AFEF")

  ;; (set-face-background 'centaur-tabs-selected-modified "#161C23")
  ;; (set-face-background 'centaur-tabs-selected          "#161C23")

  ;; (set-face-attribute 'centaur-tabs-selected nil
  ;;                     :background "#161C23"
  ;;                     :foreground "#ABB2BF"
  ;;                     :overline nil
  ;;                     :underline "#528BFF"
  ;;                     :weight light)

  ;; (set-face-underline 'centaur-tabs-selected "cyan")
  ;; modified tab underline
  (set-face-underline 'centaur-tabs-selected-modified "cyan")
  (set-face-underline 'centaur-tabs-modified-marker-selected "cyan")

  (set-face-underline 'centaur-tabs-selected-modified nil)
  (set-face-underline 'centaur-tabs-selected nil)
  (set-face-underline 'centaur-tabs-modified-marker-selected nil)


  (unless (display-graphic-p)
    (setq centaur-tabs-set-icons nil)
    (setq centaur-tabs-close-button "")
    (setq centaur-tabs-set-modified-marker t)
    (setq centaur-tabs-modified-marker "*")))


(provide 'init-centaur)
