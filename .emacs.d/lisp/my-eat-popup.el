;; -*- lexical-binding: t -*-
;;; my-eat-popup.el --- Popup eat terminal for each project

;;; Commentary:

;; `my-toggle-vterm' (s-j) opens or closes a popup eat terminal.
;; Each projectile project gets its own terminal buffer.
;; The shell starts in the project root.
;; Outside a project, all buffers share one terminal.

;;; Code:

(declare-function eat-mode "eat")
(declare-function eat-exec "eat")
(declare-function eat-term-parameter "eat")
(declare-function projectile-project-p "projectile")
(declare-function projectile-project-root "projectile")
(declare-function popper-close-latest "popper")
(defvar explicit-shell-file-name)

(defvar my-popup-eat-buffer-name "*eat-popup*"
  "Buffer name for the popup eat terminal outside any project.")

(defun my-popup-eat-project-root ()
  "Return the current projectile project root, or nil."
  (when (and (require 'projectile nil t)
             (projectile-project-p))
    (ignore-errors (projectile-project-root))))

(defun my-popup-eat-buffer-name-for-root (root)
  "Return the popup eat buffer name for project ROOT.
The hash keeps two projects with the same directory name apart."
  (let ((dir (expand-file-name (directory-file-name root))))
    (format "*eat-popup:%s-%s*"
            (file-name-nondirectory dir)
            (substring (sha1 dir) 0 8))))

(defun my-get-or-create-popup-eat-buffer ()
  "Return the popup eat buffer of the current project.
Each project gets its own buffer. The shell starts in the project root."
  (let* ((root (my-popup-eat-project-root))
         (name (if root
                   (my-popup-eat-buffer-name-for-root root)
                 my-popup-eat-buffer-name)))
    (or (get-buffer name)
        (let ((buf (get-buffer-create name)))
          (with-current-buffer buf
            ;; eat-exec starts the process in default-directory.
            (when root
              (setq default-directory root))
            (unless (eq major-mode 'eat-mode)
              (eat-mode))
            (unless (and (bound-and-true-p eat-terminal)
                         (eat-term-parameter eat-terminal 'eat--process))
              (eat-exec buf (buffer-name) "/usr/bin/env" nil
                        (list "sh" "-c" (or explicit-shell-file-name
                                            (getenv "ESHELL")
                                            shell-file-name)))))
          buf))))

(defun my-toggle-vterm ()
  "Show the eat popup of the current project, or close it when in eat."
  (interactive)
  (if (derived-mode-p 'eat-mode)
      (cond
       ((bound-and-true-p popper-mode) (popper-close-latest))
       (t (delete-window)))
    (display-buffer (my-get-or-create-popup-eat-buffer))))


(provide 'my-eat-popup)

;;; my-eat-popup.el ends here
