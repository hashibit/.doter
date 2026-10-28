;; -*- lexical-binding: t -*-
;;; my-window-buffer.el --- Window and buffer management commands

;;; Code:

(require 'seq)
(defvar popper-open-popup-alist)
(defvar ivy-ignore-buffers)


(defun my-most-recent-normal-buffer()
  "Return the most recent normal buffer."
  (interactive)
  (let ((bufs (seq-filter
               (lambda(elt) (my-god-this-is-normal-editor-buffer (buffer-name elt)))
               (buffer-list))))
    (when (length> bufs 1)
      (nth 1 bufs))))


(defun flip-buffer-to-window (&optional include-special-buffer)
  "Flip to the last-visited buffer in this window."
  (interactive)
  (let ((recent (if include-special-buffer
                    (nth 1 (buffer-list))
                  (my-most-recent-normal-buffer))))
    (switch-to-buffer (or recent (other-buffer (current-buffer))))))

(defun my-flip-buffer-to-window-in-project ()
  "Flip to the most recently visited normal buffer in the current project."
  (interactive)
  (let* ((proj (project-current))
         (proj-bufs (when proj (project-buffers proj)))
         (bufs (seq-filter
                (lambda (buf)
                  (and (my-god-this-is-normal-editor-buffer (buffer-name buf))
                       (not (eq buf (current-buffer)))
                       (or (null proj) (memq buf proj-bufs))))
                (buffer-list)))
         (recent (car bufs)))
    (switch-to-buffer (or recent (other-buffer (current-buffer))))))
;; delete all other buffers, only keep current one.
(defun my-only-current-buffer ()
  "Kill all non-star other buffers."
  (interactive)
  (let ((orig-eglot-active (bound-and-true-p eglot--managed-mode)))
    (ignore-errors (eglot-shutdown-all))
    (mapc 'kill-buffer (delq
                        (current-buffer)
                        (seq-filter #'buffer-file-name (buffer-list)))) ;; this keep * buffers alive
    (if (bound-and-true-p centaur-tabs-mode)
        (centaur-tabs-kill-other-buffers-in-current-group))
    (if orig-eglot-active (eglot-ensure))))

;; delete other file/dired buffers in current project, only keep current one.
(defun my-only-current-project-buffer ()
  "Kill other file-visiting and dired buffers in the current project."
  (interactive)
  (if-let* ((proj (project-current)))
      (let ((killed 0))
        (dolist (buf (project-buffers proj))
          (when (and (not (eq buf (current-buffer)))
                     (or (buffer-file-name buf)
                         (eq (buffer-local-value 'major-mode buf) 'dired-mode)))
            (when (kill-buffer buf)
              (setq killed (1+ killed)))))
        (message "Killed %d buffer(s) in project %s" killed (project-name proj)))
    (user-error "Not in a project")))

;; delete all other buffers, only keep current one.
(defun my-only-current-buffer-include-specials ()
  "Kill all other buffers."
  (interactive)
  ;; this destroy * buffers too, but keep internal " *..." buffers
  (dolist (buf (buffer-list))
    (unless (or (eq buf (current-buffer))
                (string-prefix-p " " (buffer-name buf)))
      (kill-buffer buf)))
  (if (bound-and-true-p centaur-tabs-mode)
      (centaur-tabs-kill-other-buffers-in-current-group))
  (if (bound-and-true-p global-eldoc-mode)
      (eldoc-box-reset-frame))
  (treemacs-find-file))
(defun my-enlarge-half-height ()
  "Expand current window to use half of the other window's lines."
  (interactive)
  (enlarge-window
   (/ (window-body-height) 4)))

(defun my-enlarge-half-width ()
  "Expand current window to use half of the other window's lines."
  (interactive)
  (enlarge-window-horizontally
   (/ (window-body-width) 4)))

(defun my-shrink-half-height ()
  "Expand current window to use half of the other window's lines."
  (interactive)
  (shrink-window
   (/ (window-body-height) 4)))

(defun my-shrink-half-width ()
  "Expand current window to use half of the other window's lines."
  (interactive)
  (shrink-window-horizontally
   (/ (window-body-width) 4)))

(defun my-enarge-window-height()
  "Make the selected window as tall as possible."
  (interactive)
  (enlarge-window 1000))
(defun my-quit-other-window()
  "Delete the other windows and close the imenu list."
  (interactive)
  (delete-other-windows)
  (ignore-errors
    (when (my-imenu-list-check-window-is-open) (imenu-list-quit-window)))
  ;; (ignore-errors
  ;;   (when (eq (treemacs-current-visibility) 'visible) (delete-window (treemacs-get-local-window))))
  (keyboard-quit))


(defun my-quit-other-buffer ()
  "Function to quit help in other-window."
  (interactive)
  (unless (one-window-p)
    (quit-window nil (next-window))))
(defun popper-toggle-but-other-window()
  "Toggle the latest popup, then select the other window."
  (interactive)
  (popper-toggle)
  (run-with-timer 0.05 nil
                  (lambda ()
                    (when popper-open-popup-alist
                      (other-window -1)))))

(defun popper-cycle-but-other-window()
  "Show the next popup, then select the other window."
  (interactive)
  (popper-cycle 0)
  (run-with-timer 0.05 nil
                  (lambda ()
                    (when popper-open-popup-alist
                      (other-window -1)))))
(defun my-project-switch-to-buffer ()
  "Switch to a buffer, or open a recent file.
Show the current project buffers first. When the input matches none of
them, search the other open buffers, then recently opened files that
are not open now, then the ignored buffers."
  (interactive)
  (let* ((ignored-p (lambda (name)
                      (seq-some (lambda (pat) (string-match-p pat name))
                                ivy-ignore-buffers)))
         (all-names (mapcar #'buffer-name (buffer-list)))
         (project-bufs (when (project-current)
                         (seq-filter (lambda (n) (not (funcall ignored-p n)))
                                     (mapcar #'buffer-name
                                             (project-buffers (project-current))))))
         (normal-bufs (seq-filter (lambda (n)
                                    (and (not (funcall ignored-p n))
                                         (not (member n project-bufs))))
                                  all-names))
         ;; recentf-list is newest first. Skip files that a buffer visits.
         (recent-files (when (bound-and-true-p recentf-list)
                         (seq-remove (lambda (f) (get-file-buffer f))
                                     (mapcar #'abbreviate-file-name recentf-list))))
         (ignored-bufs (seq-filter ignored-p all-names)))
    (ivy-read "Buffer: "
              (lambda (input)
                (if (string-empty-p input)
                    (or project-bufs normal-bufs)
                  ;; Use the first group that has a match.
                  (seq-some (lambda (group) (ivy--re-filter input group))
                            (list project-bufs normal-bufs recent-files ignored-bufs))))
              :dynamic-collection t
              :action (lambda (choice)
                        (if (get-buffer choice)
                            (switch-to-buffer choice)
                          (find-file choice)))
              :caller 'my-project-switch-to-buffer)))


(provide 'my-window-buffer)

;;; my-window-buffer.el ends here
