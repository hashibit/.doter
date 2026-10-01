;;; eat-floating.el --- Floating Eat terminal in a child frame -*- lexical-binding: t; -*-

;; Copyright (C) 2026  jiechen

;; Author: jiechen
;; Version: 0.2.0
;; Package-Requires: ((emacs "26.1") (eat "0.9"))
;; Keywords: terminals, frames

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A toggleable floating terminal built on Eat, shown as an
;; undecorated child frame centered on the current frame.
;;
;;     (require 'eat-floating)
;;     (global-set-key (kbd "C-`") #'eat-floating-toggle)
;;
;; The terminal is scoped per project: toggling inside a project
;; (projectile) shows or hides that project's own session, which is
;; created on first toggle with its working directory set to the
;; project root — handy for running `claude' against the current
;; project.  Outside any project a single default session is used.
;; Sessions keep running while the frame is hidden; toggling only
;; shows and hides the frame.  The frame is closed automatically when
;; the displayed session's process exits.

;;; Code:

(require 'eat)
(require 'projectile nil t)

(declare-function projectile-project-p "projectile" nil)
(declare-function projectile-project-root "projectile" nil)

(defgroup eat-floating nil
  "A floating Eat terminal in a child frame."
  :group 'convenience
  :prefix "eat-floating-")

(defcustom eat-floating-buffer-name "*floating-eat*"
  "Name of the floating terminal buffer used outside any project.
Inside a project the buffer is named `*floating-eat:<project>-<hash>*'."
  :type 'string
  :group 'eat-floating)

(defcustom eat-floating-width-ratio 0.85
  "Width of the floating frame, as a fraction of the parent frame."
  :type 'float
  :group 'eat-floating)

(defcustom eat-floating-height-ratio 0.85
  "Height of the floating frame, as a fraction of the parent frame."
  :type 'float
  :group 'eat-floating)

(defcustom eat-floating-shell-command
  (or explicit-shell-file-name shell-file-name (getenv "SHELL") "sh")
  "Shell command to run inside the floating terminal."
  :type 'string
  :group 'eat-floating)

(defcustom eat-floating-prewarm nil
  "Pre-start the default shell in the background after Emacs loads.

The first toggle then opens instantly: the shell startup cost (often
hundreds of ms for a configured zsh) is paid once at idle time
instead of when the terminal is first shown.  The shell process then
runs for the whole Emacs session even if the terminal is never used."
  :type 'boolean
  :group 'eat-floating)

(defvar eat-floating-frame nil
  "The floating child frame, or nil while hidden.")

(defun eat-floating--close-frame ()
  "Delete the floating frame, then restore focus to its parent.

The refocus is unconditional: on macOS the NS port only redraws a
frame's cursor after `windowDidBecomeKey' (driven by `x-focus-frame'),
and the call is skipped when the parent is already the tracked focus
frame, so no extra guard is applied here."
  (when (frame-live-p eat-floating-frame)
    (let ((parent (frame-parent eat-floating-frame)))
      (delete-frame eat-floating-frame)
      (setq eat-floating-frame nil)
      (when (and parent (frame-live-p parent))
        (select-frame-set-input-focus parent)
        ;; Force a full redraw so the cursor is repainted even if the
        ;; NS focus event is missed.
        (force-window-update parent)))))

(defun eat-floating--on-frame-deleted (frame)
  "Clear `eat-floating-frame' when FRAME is deleted by other means.
Keeps the toggle state consistent if the frame is closed through
`delete-other-frames', killing its parent frame, etc."
  (when (eq frame eat-floating-frame)
    (setq eat-floating-frame nil)))

(add-hook 'delete-frame-functions #'eat-floating--on-frame-deleted)

(defun eat-floating--on-process-exit (_process)
  "Close the floating frame when the displayed session's process exits.
The teardown is deferred with a zero timer: focus and redraw calls
made from inside a process sentinel leave the parent frame's cursor
undrawn on macOS NS, while the same calls from the timer context
behave like the interactive toggle.  The hook is buffer-local, so
`current-buffer' is the session whose process exited; a hidden
session's exit does not touch the frame."
  (when (and (frame-live-p eat-floating-frame)
             (eq (current-buffer)
                 (window-buffer (frame-selected-window eat-floating-frame))))
    (let ((frame eat-floating-frame))
      (run-with-timer 0 nil
                      (lambda ()
                        ;; The user may have re-toggled a new session in
                        ;; the meantime; only close the recorded frame.
                        (when (eq frame eat-floating-frame)
                          (eat-floating--close-frame)))))))

(defun eat-floating--project-root ()
  "Return the current project's root, or nil outside any project."
  (when (and (require 'projectile nil t)
             (fboundp 'projectile-project-p)
             (projectile-project-p))
    (ignore-errors (projectile-project-root))))

(defun eat-floating--buffer-name-for-root (root)
  "Return the floating terminal buffer name for project ROOT."
  (let* ((dir (expand-file-name (directory-file-name root)))
         (base (file-name-nondirectory dir))
         (hash (substring (sha1 dir) 0 8)))
    (format "*floating-eat:%s-%s*" base hash)))

(defun eat-floating--project-buffer-name ()
  "Buffer name of the current project's floating terminal.
Outside any project, `eat-floating-buffer-name'."
  (if-let* ((root (eat-floating--project-root)))
      (eat-floating--buffer-name-for-root root)
    eat-floating-buffer-name))

(defun eat-floating-project-buffer ()
  "Return the current project's floating Eat buffer, or nil."
  (get-buffer (eat-floating--project-buffer-name)))

(defun eat-floating--ensure-buffer (&optional root)
  "Return the Eat buffer for project ROOT (current project if nil).
Start the shell if it is not running; on first start the working
directory is ROOT (no cd outside a project)."
  (let* ((root (or root (eat-floating--project-root)))
         (name (if root
                   (eat-floating--buffer-name-for-root root)
                 eat-floating-buffer-name))
         (buffer (get-buffer-create name)))
    (with-current-buffer buffer
      ;; `eat-exec' does not set the buffer mode, so enable it first.
      (unless (and (derived-mode-p 'eat-mode)
                   (get-buffer-process buffer))
        (when root
          ;; `eat-exec' spawns the process from the buffer's
          ;; `default-directory', so this cd applies on first open.
          (setq-local default-directory root))
        (eat-mode)
        (eat-exec buffer name eat-floating-shell-command nil nil))

      ;; Buffer-local setup goes after `eat-mode': the major mode's
      ;; `kill-all-local-variables' would wipe it otherwise.

      ;; Depth 0: close the frame before eat's own `eat--kill-buffer'
      ;; (depth 90) kills the buffer — otherwise the child frame would
      ;; be left on screen showing a replacement buffer.
      (add-hook 'eat-exit-hook #'eat-floating--on-process-exit 0 t)

      ;; Replace special emoji with plain text.
      (let ((tbl (or buffer-display-table
                     (setq buffer-display-table (make-display-table)))))
        (dolist (pair '((#x273B . ?*)        ; ✻ TEARDROP-SPOKED ASTERISK
                        (#x273D . ?*)        ; ✽ HEAVY TEARDROP-SPOKED ASTERISK
                        (#x2722 . ?+)        ; ✢ FOUR TEARDROP-SPOKED ASTERISK
                        (#x2736 . ?+)        ; ✶ SIX-POINTED BLACK STAR
                        (#x2733 . ?*)        ; ✳ EIGHT SPOKED ASTERISK
                        (#x23FA . ?\u25CF))) ; ⏺ RECORD BUTTON
          (aset tbl (car pair) (vector (cdr pair))))))
    buffer))

(defun eat-floating--show-buffer (buffer &optional focus)
  "Display BUFFER in the floating frame, creating the frame if needed.
Focus the frame when FOCUS is non-nil."
  (let* ((frame (if (frame-live-p eat-floating-frame)
                    (progn
                      (make-frame-visible eat-floating-frame)
                      eat-floating-frame)
                  (eat-floating--create-frame)))
         (win (frame-selected-window frame)))
    (unless (eq (window-buffer win) buffer)
      (set-window-dedicated-p win nil)
      (set-window-buffer win buffer)
      (set-window-dedicated-p win t))
    (when focus
      (select-frame-set-input-focus frame))
    (redisplay)))

(defun eat-floating-ensure-visible (&optional buffer)
  "Show the floating terminal, creating the current project's session if needed.
Show BUFFER when given.  The frame is focused only when it was hidden;
when already visible, its buffer is switched in place instead."
  (let ((buffer (or buffer (eat-floating--ensure-buffer))))
    (if (and (frame-live-p eat-floating-frame)
             (frame-visible-p eat-floating-frame))
        (eat-floating--show-buffer buffer)
      (eat-floating--show-buffer buffer t))
    buffer))

(defun eat-floating--prewarm ()
  "Start the default floating shell in the background, if enabled."
  (when eat-floating-prewarm
    (eat-floating--ensure-buffer)))

(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-idle-timer 5 nil #'eat-floating--prewarm)))

(defun eat-floating--create-frame ()
  "Create the centered floating child frame and return it."
  (let* ((parent (selected-frame))
         (p-width (frame-pixel-width parent))
         (p-height (frame-pixel-height parent))
         (f-width (truncate (* p-width eat-floating-width-ratio)))
         (f-height (truncate (* p-height eat-floating-height-ratio)))
         ;; Create the frame invisible, then size/position it, then show
         ;; it once: creating it visible first would paint the window at
         ;; the default size and leave a visible move/resize trail on
         ;; macOS.
         (new-frame
          (make-frame
           `((parent-frame . ,parent)
             (visibility . nil)
             ;; `make-frame' merges `default-frame-alist' into every new
             ;; frame; override the inherited `fullscreen' so a maximized
             ;; default does not pin the child frame to full size and
             ;; make `set-frame-size' a no-op.
             (fullscreen . nil)
             (undecorated . t)
             (unsplittable . t)
             (accept-focus . t)            ; allow mouse and keyboard focus
             (auto-raise . t)
             (tab-bar-lines . 0)           ; no tab bar in the floating frame
             (minibuffer . nil)
             (vertical-scroll-bars . nil)
             (horizontal-scroll-bars . nil)))))
    ;; Note: the size is applied with `set-frame-size' (pixelwise)
    ;; rather than via `width'/'height' parameters — the
    ;; `frame-resize-pixelwise' dynamic binding is not picked up by
    ;; `make-frame' on Emacs 31, so pixel width/height parameters are
    ;; misread as character units there.
    (set-frame-size new-frame f-width f-height t)
    ;; Center based on the frame's actual pixel size: the size applied
    ;; above differs from the requested one by the window frame
    ;; (borders/shadows), so centering on the requested size would
    ;; leave the frame a few pixels off.
    (set-frame-position
     new-frame
     (truncate (/ (- p-width (frame-pixel-width new-frame)) 2))
     (truncate (/ (- p-height (frame-pixel-height new-frame)) 2)))
    (make-frame-visible new-frame)
    (setq eat-floating-frame new-frame)
    new-frame))

;;;###autoload
(defun eat-floating-toggle ()
  "Show or hide the floating Eat terminal for the current project.
When the frame is already visible with a different project's session,
switch to the current project's session instead of hiding."
  (interactive)
  (let ((buffer (eat-floating--ensure-buffer)))
    (if (and (frame-live-p eat-floating-frame)
             (frame-visible-p eat-floating-frame))
        (if (eq (window-buffer (frame-selected-window eat-floating-frame))
                buffer)
            (eat-floating--close-frame)
          ;; Visible but showing another project's session: switch.
          (eat-floating--show-buffer buffer t))
      (eat-floating--show-buffer buffer t))))

;;;###autoload
(defun eat-floating-kill ()
  "Close the floating terminal and kill the current project's shell process."
  (interactive)
  (eat-floating--close-frame)
  (let ((buffer (eat-floating-project-buffer)))
    (when (buffer-live-p buffer)
      (kill-buffer buffer))))

;; Backward compatibility with the pre-package name.
(defalias 'my-toggle-floating-eat #'eat-floating-toggle)

(provide 'eat-floating)
;;; eat-floating.el ends here
