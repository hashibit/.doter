;; -*- lexical-binding: t -*-
;;; init-eat-claude.el --- Send buffers/regions to a claude session in Eat

;;; Commentary:

;; The `claude-code.el' file/region sending, without the package: the
;; `claude' CLI runs inside the floating Eat terminal (eat-floating.el),
;; and these commands type a claude file reference into it, which claude
;; resolves to the file's content:
;;
;;     SPC a b  (my-eat-claude-send-buffer)  @/abs/path/to/file
;;     SPC a s  (my-eat-claude-send-region)  @/abs/path/to/file:START-END
;;
;; Only the references are typed, never file contents — claude reads
;; the file itself.  The terminal must already be running `claude' (or
;; `claude-code-ds'/`claude-code-bailian' style env), started manually
;; with `eat-floating-toggle'.

;;; Code:

(require 'eat-floating)
(require 'cl-lib)

;; eat 由 eat-floating 加载，这里只声明用到的符号
(declare-function eat-term-send-string "eat")
(defvar eat-terminal)

(defgroup my-eat-claude nil
  "Send Emacs files/regions to a `claude' session in Eat."
  :group 'convenience)

(defcustom my-eat-claude-buffer-name nil
  "Eat buffer that runs the `claude' session.
Nil uses the current project's floating Eat terminal (eat-floating),
or the default one outside any project, falling back to the most
recently used Eat buffer."
  :type '(choice (const :tag "Auto" nil) string)
  :group 'my-eat-claude)

(defcustom my-eat-claude-auto-show t
  "Pop up the floating Eat terminal after sending, so the reply is visible."
  :type 'boolean
  :group 'my-eat-claude)

(defun my-eat-claude--buffer ()
  "Return the Eat buffer that should receive input, or nil."
  (or (and my-eat-claude-buffer-name
           (get-buffer my-eat-claude-buffer-name))
      (eat-floating-project-buffer)
      (get-buffer eat-floating-buffer-name)
      (cl-find-if (lambda (buf)
                    (with-current-buffer buf
                      (derived-mode-p 'eat-mode)))
                  (buffer-list))))

(defun my-eat-claude--send-string (string)
  "Send STRING as terminal input in the current Eat buffer."
  (let ((inhibit-read-only t))
    (eat-term-send-string eat-terminal string)))

(defun my-eat-claude--file-ref ()
  "Return a `claude' file reference for the current buffer."
  (let ((file (buffer-file-name)))
    (unless file
      (user-error "Current buffer is not visiting a file"))
    (format "@%s" file)))

(defun my-eat-claude--region-ref ()
  "Return a `claude' file reference for the active region."
  (let* ((file (buffer-file-name))
         (beg (region-beginning))
         (stop (region-end))
         (start (line-number-at-pos beg))
         ;; 选区结束在行首时（如整行选择），不包含那一行
         (end (line-number-at-pos (if (and (> stop beg)
                                           (save-excursion (goto-char stop) (bolp)))
                                      (1- stop)
                                    stop))))
    (unless file
      (user-error "Current buffer is not visiting a file"))
    (if (= start end)
        (format "@%s:%d" file start)
      (format "@%s:%d-%d" file start end))))

(defun my-eat-claude--floating-p (buf)
  "Return non-nil when BUF is one of the floating Eat terminal buffers."
  (and buf (string-match-p "\\`\\*floating-eat" (buffer-name buf))))

(defun my-eat-claude--show (buf &optional force-show)
  "Make the floating terminal visible when BUF is one of its buffers.
Show regardless of `my-eat-claude-auto-show' when FORCE-SHOW is non-nil."
  (when (and (my-eat-claude--floating-p buf)
             (or my-eat-claude-auto-show force-show))
    (eat-floating-ensure-visible buf)))

(defun my-eat-claude--send-ref (ref &optional deactivate force-show)
  "Type REF into the Eat session running `claude'.
Start the floating terminal first if none exists.  When DEACTIVATE is
non-nil, clear the active region after sending.  FORCE-SHOW is passed
to `my-eat-claude--show'."
  (let* ((buf (my-eat-claude--buffer))
         (fresh (not buf)))
    (unless buf
      (eat-floating-ensure-visible)
      (setq buf (my-eat-claude--buffer))
      (unless buf
        (user-error "No Eat terminal running")))
    (if fresh
        (message "New terminal: start `claude' inside it, then press the key again")
      (with-current-buffer buf
        (my-eat-claude--send-string (concat ref "\n")))
      (my-eat-claude--show buf force-show)
      (when deactivate
        (deactivate-mark)))))

(defun my-eat-claude-send-buffer ()
  "Send the current file to the `claude' session in Eat."
  (interactive)
  (my-eat-claude--send-ref (my-eat-claude--file-ref)))

(defun my-eat-claude-send-region ()
  "Send the active region to the `claude' session in Eat."
  (interactive)
  (unless (use-region-p)
    (user-error "No active region"))
  (my-eat-claude--send-ref (my-eat-claude--region-ref) t))

(defun my-eat-claude-send-command (cmd &optional arg)
  "Send CMD to the `claude' session in Eat, with the current buffer as context.
With an active region the context is the region's line range
\(@file:START-END); otherwise the whole file (@file).
With prefix ARG, show the terminal after sending."
  (interactive "sClaude command: \nP")
  (let ((context (if (use-region-p)
                     (my-eat-claude--region-ref)
                   (my-eat-claude--file-ref))))
    (my-eat-claude--send-ref (format "%s\n%s" cmd context)
                             (use-region-p)
                             arg)))

;; Same key as the old `claude-code.el' setup: command with
;; buffer/region context.
(bind-key "s-y" #'my-eat-claude-send-command)

(provide 'init-eat-claude)
;;; init-eat-claude.el ends here
