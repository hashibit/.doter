;;; -*- lexical-binding: t -*-
(require 'ibuffer)
(require 'ibuf-ext)
(defvar dired-dwim-target)

(setq ibuffer-formats '((mark modified " "
                         (name 24 24 :left :elide)
                         " "
                          filename)
                         (mark modified read-only locked " "
                           (name 18 18 :left :elide)
                           " "
                           (size 9 -1 :right)
                           " "
                           (mode 16 16 :left :elide)
                           " "
                           filename-and-process)
                         ))

(define-ibuffer-filter my-visiting-file
  "Limit current view to buffers that are visiting a file."
  (:description "visiting a file"
    :reader nil)
  (buffer-file-name buf))

(defun my-side-ibuffer-revert (&rest _)
  (ibuffer-update nil t))

(defun my-side-ibuffer-visit-and-quit-other ()
  (interactive)
  (ibuffer-visit-buffer-other-window)
  (my-quit-other-window))

(defvar-keymap my-side-ibuffer-map
  :parent ibuffer-mode-map
  "q" #'kill-current-buffer
  "v" #'ibuffer-visit-buffer-other-window-noselect
  "o" #'ibuffer-visit-buffer-other-window
  "<mouse-1>" #'ibuffer-visit-buffer-other-window
  "RET" #'my-side-ibuffer-visit-and-quit-other)

(defun side-ibuffer ()
  (interactive)
  (let ((buffer
          (save-window-excursion
            (ibuffer nil "*side-ibuffer*" '((my-visiting-file . t)))
            (setq-local buffer-stale-function #'always)
            (setq-local revert-buffer-function #'my-side-ibuffer-revert)
            (auto-revert-mode -1)
            (setq-local display-buffer-base-action '(display-buffer-use-some-window))
            (use-local-map my-side-ibuffer-map)
            (current-buffer))))
    (pop-to-buffer buffer
      '(display-buffer-in-side-window
         (side . right)))))

;; add another sorting method for ibuffer (allow the grouping of
;; filenames and dired buffers
(define-ibuffer-sorter filename-or-dired
  "Sort the buffers by their pathname."
  (:description "filenames plus dired")
  (string-lessp
    (with-current-buffer (car a)
      (or buffer-file-name
        (if (eq major-mode 'dired-mode)
          (expand-file-name dired-directory))
        ;; so that all non pathnames are at the end
        "~"))
    (with-current-buffer (car b)
      (or buffer-file-name
        (if (eq major-mode 'dired-mode)
          (expand-file-name dired-directory))
        ;; so that all non pathnames are at the end
        "~"))))

(keymap-set ibuffer-mode-map "s p" #'ibuffer-do-sort-by-filename-or-dired)

(defun my-ibuffer-hook ()
  ;; sort now please!
  (ibuffer-do-sort-by-filename-or-dired))

(add-hook 'ibuffer-mode-hook #'my-ibuffer-hook)

(with-eval-after-load 'dired
  (setq dired-dwim-target t))

(provide 'init-dired-ibuffer)
