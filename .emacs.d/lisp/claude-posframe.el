;;; claude-posframe.el --- Claude terminal interface using posframe -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: Claude & User
;; Version: 1.2.0
;; Package-Requires: ((emacs "26.1") (posframe "1.0.0") (eat "0.9"))
;; Keywords: convenience, terminal, claude
;; URL:

;;; Commentary:

;; This package provides a posframe-based terminal interface for Claude.
;; It creates a floating terminal window that can be toggled on/off.
;; The package includes customizable dimensions, colors, and behavior.
;;
;; Usage:
;;   (require 'claude-posframe)
;;   (claude-posframe-mode 1)  ; Enable in current buffer
;;   ;; or
;;   (global-claude-posframe-mode 1)  ; Enable globally
;;
;; Key bindings (when claude-posframe-mode is active):
;;   C-c a t - Toggle Claude posframe
;;   C-,     - Toggle Claude posframe (quick alternative)
;;   C-c a k - Kill Claude posframe buffer
;;   C-c a r - Restart Claude posframe
;;   C-c a b - Send current buffer file to Claude
;;   C-c a s - Send selected region to Claude

;;; Code:

(eval-when-compile
  (require 'cl-lib))

;;; Dependencies and Declarations

(declare-function posframe-show "posframe")
(declare-function posframe-hide "posframe")
(declare-function posframe-poshandler-frame-center "posframe")
(declare-function eat-make "eat")
(declare-function eat-term-send-string "eat")

;; Soft dependency handling
(defvar claude-posframe--dependencies-available nil
  "Whether required dependencies are available.")

(defun claude-posframe--check-dependencies ()
  "Check if required dependencies are available."
  (unless claude-posframe--dependencies-available
    (setq claude-posframe--dependencies-available
      (and (require 'posframe nil t)
        (require 'eat nil t))))
  claude-posframe--dependencies-available)

;;; Customization

(defgroup claude-posframe nil
  "Claude posframe configuration."
  :group 'convenience
  :prefix "claude-posframe-")

(defcustom claude-posframe-width-ratio 0.75
  "Width ratio of the posframe relative to the frame width."
  :type 'float
  :group 'claude-posframe)

(defcustom claude-posframe-height-ratio 0.75
  "Height ratio of the posframe relative to the frame height."
  :type 'float
  :group 'claude-posframe)

(defcustom claude-posframe-border-width 1
  "Border width of the posframe."
  :type 'integer
  :group 'claude-posframe)

(defcustom claude-posframe-border-color "green"
  "Border color of the posframe."
  :type 'string
  :group 'claude-posframe)

(defcustom claude-posframe-shell "claude"
  "Shell command to run in the eat buffer."
  :type 'string
  :group 'claude-posframe)

(defcustom claude-posframe-position 'center
  "Position of the posframe."
  :type '(choice (const :tag "Center" center)
           (const :tag "Top" top)
           (const :tag "Bottom" bottom)
           (const :tag "Left" left)
           (const :tag "Right" right))
  :group 'claude-posframe)

(defcustom claude-posframe-min-width 80
  "Minimum width of the posframe."
  :type 'integer
  :group 'claude-posframe)

(defcustom claude-posframe-min-height 20
  "Minimum height of the posframe."
  :type 'integer
  :group 'claude-posframe)

(defcustom claude-posframe-auto-scroll t
  "Whether to automatically scroll to bottom when showing posframe."
  :type 'boolean
  :group 'claude-posframe)

(defcustom claude-posframe-working-directory nil
  "Working directory for the claude eat process.
If nil, automatically detect project directory using projectile, project.el, or vc.
Falls back to current directory if no project is detected."
  :type '(choice (const :tag "Auto-detect project directory" nil)
           (directory :tag "Custom directory"))
  :group 'claude-posframe)

(defcustom claude-posframe-fix-unicode t
  "Whether to apply Unicode character fixes to prevent line jitter."
  :type 'boolean
  :group 'claude-posframe)

(defconst claude-posframe-buffer-base-name "*claude-posframe*"
  "Base name of the claude posframe buffer.")

;;; Variables and State

(defvar claude-posframe--parent-frame nil
  "Store the parent frame to restore focus after hiding posframe.")

;;; Utility Functions

(defun claude-posframe--get-buffer-name ()
  "Get project-specific buffer name."
  (let ((project-dir (claude-posframe--get-project-directory)))
    (if project-dir
      (format "*claude-posframe:%s*" (file-name-nondirectory (directory-file-name project-dir)))
      claude-posframe-buffer-base-name)))

;;; Hooks
(defvar claude-posframe-show-hook nil
  "Hook run after showing the claude posframe.")

(defvar claude-posframe-hide-hook nil
  "Hook run after hiding the claude posframe.")

(defvar claude-posframe-kill-hook nil
  "Hook run before killing the claude posframe buffer.")


(defun claude-posframe--get-position-handler ()
  "Get the position handler based on customization."
  (pcase claude-posframe-position
    ('center #'posframe-poshandler-frame-center)
    ('top #'posframe-poshandler-frame-top-center)
    ('bottom #'posframe-poshandler-frame-bottom-center)
    ('left #'posframe-poshandler-frame-left-center)
    ('right #'posframe-poshandler-frame-right-center)
    (_ #'posframe-poshandler-frame-center)))

(defun claude-posframe--get-project-directory ()
  "Get the project root directory, trying multiple methods."
  (or
    (when (and (bound-and-true-p projectile-mode)
            (fboundp 'projectile-project-root))
      (ignore-errors (projectile-project-root)))
    (when (fboundp 'project-current)
      (when-let ((project (project-current)))
        (if (fboundp 'project-root)
          (project-root project)
          (car (project-roots project)))))
    (when (fboundp 'vc-root-dir)
      (ignore-errors (vc-root-dir)))
    default-directory))

;;; Core Functions

(defun claude-posframe--calculate-dimensions ()
  "Calculate posframe dimensions with minimum constraints."
  (let ((width (max claude-posframe-min-width
                 (round (* (frame-width) claude-posframe-width-ratio))))
         (height (max claude-posframe-min-height
                   (round (* (frame-height) claude-posframe-height-ratio)))))
    (list width height)))

;;;###autoload
(defun claude-posframe-show (&optional switches)
  "Show the claude posframe."
  (interactive)
  (unless (claude-posframe--check-dependencies)
    (user-error "Required dependencies (posframe, eat) are not available"))
  (let* ((buffer (claude-posframe--get-buffer switches))
          (dimensions (claude-posframe--calculate-dimensions))
          (width (car dimensions))
          (height (cadr dimensions)))
    (setq claude-posframe--parent-frame (selected-frame))
    (posframe-show buffer
      :position (point)
      :width width
      :height height
      :window-point (when claude-posframe-auto-scroll
                      (with-current-buffer buffer (point-max)))
      :border-width claude-posframe-border-width
      :border-color claude-posframe-border-color
      :poshandler (claude-posframe--get-position-handler)
      :accept-focus t)
    (when claude-posframe-auto-scroll
      (claude-posframe--ensure-scroll))
    (run-hooks 'claude-posframe-show-hook)))

;;; Display and Interaction Functions

(defun claude-posframe--ensure-scroll ()
  "Ensure the claude posframe scrolls to bottom."
  (let ((buffer (get-buffer (claude-posframe--get-buffer-name))))
    (when (and buffer (buffer-live-p buffer) (claude-posframe-visible-p))
      (with-current-buffer buffer
        (goto-char (point-max)))
      (dolist (win (get-buffer-window-list buffer nil t))
        (when (window-live-p win)
          (with-selected-window win
            (goto-char (point-max))
            (recenter -1)))))))


;;;###autoload
(defun claude-posframe-hide ()
  "Hide the claude posframe."
  (interactive)
  (let ((buffer (get-buffer (claude-posframe--get-buffer-name))))
    (when (and buffer (buffer-live-p buffer))
      (posframe-hide buffer)
      (when (and claude-posframe--parent-frame
              (frame-live-p claude-posframe--parent-frame))
        (select-frame-set-input-focus claude-posframe--parent-frame))
      (run-hooks 'claude-posframe-hide-hook))))


(defun claude-posframe-visible-p ()
  "Check if the claude posframe is visible."
  (let ((buffer (get-buffer (claude-posframe--get-buffer-name))))
    (and buffer
      (buffer-live-p buffer)
      (let ((window (get-buffer-window buffer t)))
        (and window
          (window-live-p window)
          (let ((frame (window-frame window)))
            (and frame
              (frame-live-p frame)
              (frame-visible-p frame))))))))

;;;###autoload
(defun claude-posframe-toggle (&optional arg)
  "Toggle the claude posframe visibility.
With prefix argument ARG (C-u), start Claude with bypassed permissions."
  (interactive "P")
  (let ((switches (when (equal arg '(4))
                    '("--permission-mode" "bypassPermissions"))))
    (if (claude-posframe-visible-p)
      (claude-posframe-hide)
      (claude-posframe-show switches))))

;;;###autoload
(defun claude-posframe-kill-buffer ()
  "Kill the claude posframe buffer."
  (interactive)
  (let ((buffer (get-buffer (claude-posframe--get-buffer-name))))
    (when (and buffer (buffer-live-p buffer))
      (run-hooks 'claude-posframe-kill-hook)
      (claude-posframe-hide)
      (kill-buffer buffer)
      (message "Claude posframe buffer killed"))))

;;;###autoload
(defun claude-posframe-restart ()
  "Restart the claude posframe by killing and recreating the buffer."
  (interactive)
  (claude-posframe-kill-buffer)
  (claude-posframe-show))

;;; Minor Mode Definition
(defvar claude-posframe-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c a t") #'claude-posframe-toggle)
    (define-key map (kbd "C-,") #'claude-posframe-toggle)
    (define-key map (kbd "C-c a k") #'claude-posframe-kill-buffer)
    (define-key map (kbd "C-c a r") #'claude-posframe-restart)
    (define-key map (kbd "C-c a b") #'claude-posframe-send-buffer-file)
    (define-key map (kbd "C-c a s") #'claude-posframe-send-region)
    map)
  "Keymap for `claude-posframe-mode'.")

;;;###autoload
(define-minor-mode claude-posframe-mode
  "Minor mode for Claude posframe integration."
  :init-value nil
  :lighter " Claude"
  :keymap claude-posframe-mode-map
  :group 'claude-posframe
  (if claude-posframe-mode
    (message "Claude posframe mode enabled")
    (message "Claude posframe mode disabled")))

;;;###autoload
(define-globalized-minor-mode global-claude-posframe-mode
  claude-posframe-mode
  (lambda () (claude-posframe-mode 1))
  :group 'claude-posframe)

;;;###autoload
(defun claude-posframe-setup-keybindings ()
  "Deprecated. Use `claude-posframe-mode' instead."
  (interactive)
  (claude-posframe-mode 1)
  (message "Claude posframe keybindings set up (consider using claude-posframe-mode instead)"))

;;; Buffer Management

(defun claude-posframe--get-buffer (&optional switches)
  "Get or create the claude eat buffer."
  (unless (claude-posframe--check-dependencies)
    (user-error "Required dependencies (posframe, eat) are not available"))

  (let* ((buffer-name (claude-posframe--get-buffer-name))
          (buffer (get-buffer buffer-name))
          (current-dir (or claude-posframe-working-directory
                         (claude-posframe--get-project-directory)
                         (expand-file-name "~"))))

    ;; Kill buffer if process is dead
    (when (and buffer (buffer-live-p buffer)
               (not (process-live-p (get-buffer-process buffer))))
      (kill-buffer buffer)
      (setq buffer nil))

    (unless buffer
      (let ((default-directory current-dir))
        (condition-case err
          (progn
            (setq buffer (apply #'eat-make buffer-name claude-posframe-shell nil switches))
            (with-current-buffer buffer
              (when claude-posframe-fix-unicode
                (claude-posframe--setup-unicode-fixes))
              (claude-posframe--setup-eat-keybindings)
              (when (get-buffer-process buffer)
                (set-process-sentinel (get-buffer-process buffer)
                  #'claude-posframe--process-sentinel))))
          (error
           (when (get-buffer buffer-name) (kill-buffer buffer-name))
           (signal (car err) (cdr err))))))
    buffer))

(defun claude-posframe--setup-unicode-fixes ()
  "Configure Unicode character replacements for Claude Code compatibility."
  (let ((tbl (or buffer-display-table (setq buffer-display-table (make-display-table)))))
    (dolist (pair
              '((#x273B . ?*) (#x273D . ?*) (#x2722 . ?+) (#x2736 . ?+) (#x2733 . ?*)
                (#x2699 . ?*) (#x1F4DD . ?*) (#x1F916 . ?*) (#x00A0 . ? )))
      (aset tbl (car pair) (vector (cdr pair))))))

;;; eat Integration

(defun claude-posframe--eat-send-return ()
  "Send return key to eat terminal."
  (interactive)
  (eat-term-send-string eat-terminal "\r"))

(defun claude-posframe--eat-send-alt-return ()
  "Send Alt+Return to eat terminal."
  (interactive)
  (eat-term-send-string eat-terminal "\e\r"))

(defun claude-posframe--setup-eat-keybindings ()
  "Set up Claude Code specific key bindings in eat buffer."
  (use-local-map (copy-keymap eat-semi-char-mode-map))
  (local-set-key (kbd "<return>") #'claude-posframe--eat-send-return)
  (local-set-key (kbd "<M-return>") #'claude-posframe--eat-send-alt-return))

(defun claude-posframe--process-sentinel (process event)
  "Handle eat process termination."
  (when (memq (process-status process) '(exit signal))
    (let ((buffer (process-buffer process)))
      (when (buffer-live-p buffer)
        (posframe-hide buffer)
        (message "Claude process exited in buffer %s" (buffer-name buffer))
        (run-with-timer 0.1 nil
          (lambda (buf)
            (when (buffer-live-p buf)
              (kill-buffer buf)))
          buffer)))))

;;; Send Commands to Claude

(defun claude-posframe-do-send-command (text)
  "Send TEXT to the claude eat buffer."
  (let ((buffer (claude-posframe--get-buffer)))
    (with-current-buffer buffer
      (eat-term-send-string eat-terminal text))
    (claude-posframe-show)))

(defun claude-posframe-send-region (beg end)
  "Send the selected region to claude posframe."
  (interactive "r")
  (let ((file-name (claude-posframe--get-buffer-file-name))
         (selection (buffer-substring-no-properties beg end)))
    (if file-name
      (claude-posframe-do-send-command (format "@%s:%d-%d\n" file-name (line-number-at-pos beg) (line-number-at-pos end)))
      (claude-posframe-do-send-command (format "%s\n" selection)))))


(defun claude-posframe--get-buffer-file-name ()
  "Get the current buffer's file name."
  (when buffer-file-name
    (file-local-name (file-truename buffer-file-name))))

(defun claude-posframe-send-buffer-file ()
  "Send the current buffer's file to Claude."
  (interactive)
  (let ((filename (claude-posframe--get-buffer-file-name)))
    (if filename
      (claude-posframe-do-send-command (format "@%s " filename))
      (message "Current buffer is not visiting a file"))))

;;; Cleanup and Initialization
(defun claude-posframe--cleanup ()
  "Clean up claude posframe resources."
  (dolist (buffer (buffer-list))
    (when (string-match-p "\*claude-posframe:" (buffer-name buffer))
      (when (buffer-live-p buffer)
        (posframe-hide buffer)
        (kill-buffer buffer))))
  (let ((buffer (get-buffer claude-posframe-buffer-base-name)))
    (when (and buffer (buffer-live-p buffer))
      (posframe-hide buffer)
      (kill-buffer buffer))))

(add-hook 'kill-emacs-hook #'claude-posframe--cleanup)

;;;###autoload
(defun claude-posframe-auto-enable ()
  "Automatically enable claude-posframe-mode for programming modes."
  (when (derived-mode-p 'prog-mode 'text-mode)
    (claude-posframe-mode 1)))

(provide 'claude-posframe)
;;; claude-posframe.el ends here
