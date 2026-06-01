;;; init-native-speaker.el --- Send buffer content to NativeSpeaker HUD via TCP -*- lexical-binding: t -*-
;;
;; Two capture modes:
;;
;;   eat terminal  — tracks input-start (after prompt) to line-end, so cursor
;;                   position (C-b, C-a, C-e) doesn't affect what's captured.
;;                   Enabled automatically when eat loads.
;;
;;   text buffer   — `native-speaker-mode' minor mode; sends full buffer content
;;                   (debounced, diff-checked) after any change.  Enable manually
;;                   in buffers you care about.
;;
;; Both use an async TCP connection (:nowait t) so a dead NativeSpeaker never
;; blocks Emacs.

;;; Code:

(defvar ns/port 12345  "TCP port NativeSpeaker listens on.")
(defvar ns/process nil "Active TCP process, or nil.")
(defvar ns/enabled nil "Non-nil when eat tracking is active.")
(defvar ns/last-sent  "" "Last string sent; used for diff-check.")
(defvar-local ns/debounce-timer nil "Pending debounce timer handle (buffer-local).")
(defvar-local ns/input-start nil "Buffer position right after the eat prompt.")

;;; ── Connection ────────────────────────────────────────────────────────────────

(defun ns/connect ()
  (condition-case err
      (progn
        (setq ns/process
              (make-network-process
               :name    "native-speaker"
               :host    "localhost"
               :service ns/port
               :family  'ipv4
               :nowait  t
               :sentinel
               (lambda (proc event)
                 (cond
                  ((string-match-p "open" event)
                   (setq ns/process proc))
                  ((string-match-p "failed\\|closed\\|deleted" event)
                   (setq ns/process nil)
                   (message "NativeSpeaker: %s" (string-trim event)))))))
        t)
    (error
     (message "NativeSpeaker: connect error — %s" (error-message-string err))
     nil)))

(defun ns/disconnect ()
  (when (and ns/process (process-live-p ns/process))
    (delete-process ns/process))
  (setq ns/process nil))

(defun reconnect-native-speaker ()
  "Drop and re-establish the TCP connection to NativeSpeaker."
  (interactive)
  (ns/disconnect)
  (if (ns/connect)
      (message "NativeSpeaker: reconnecting…")
    (message "NativeSpeaker: reconnect failed")))

;;; ── Send ──────────────────────────────────────────────────────────────────────

(defun ns/send (text)
  "Send TEXT to NativeSpeaker. No-op if not connected."
  (when (and ns/process (process-live-p ns/process))
    (condition-case nil
        (process-send-string ns/process (concat text "\n"))
      (error nil))))

(defun ns/send-if-changed (text)
  "Send TEXT only when it differs from the last sent value."
  (unless (string= text ns/last-sent)
    (setq ns/last-sent text)
    (ns/send text)))

(defun native-speaker-clear ()
  "Blank the NativeSpeaker HUD."
  (interactive)
  (setq ns/last-sent "")
  (ns/send "")
  (message "NativeSpeaker: cleared"))

(defun native-speaker-send-region (beg end)
  "Send the active region (or current line) to NativeSpeaker."
  (interactive "r")
  (ns/send (string-trim
            (if (use-region-p)
                (buffer-substring-no-properties beg end)
              (thing-at-point 'line t)))))

;;; ── eat: hook into eat-update-hook (after-change-functions is suppressed) ───

(defvar ns/prompt-regexp "^\\s-*[❯❮$%#>➜λ»·►▶]+\\s-*"
  "Regexp matching a shell prompt prefix at the start of the input line.
Stripped from captured input so only what the user typed is sent.")

(defun ns/eat-get-input ()
  "Return what the user typed on the current prompt line.

The terminal cursor always sits on the line the user is typing into, so
we read from that line's beginning up to the cursor and strip the shell
prompt prefix.  This is robust against starship-style multi-line prompts:
the separator and git-info decorations live on *other* buffer lines (drawn
via ANSI cursor movement) and are therefore never captured — unlike
`eat-term-end' (grabs the RPROMPT) or a post-prompt marker (lands on the
wrong row when the prompt redraws)."
  (when (and (bound-and-true-p eat-terminal)
             (eat-term-live-p eat-terminal))
    (let* ((cursor     (eat-term-display-cursor eat-terminal))
           (line-start (save-excursion
                         (goto-char cursor)
                         (line-beginning-position))))
      (when (< line-start cursor)
        (let* ((raw  (replace-regexp-in-string
                      "[[:cntrl:]]" ""
                      (buffer-substring-no-properties line-start cursor)))
               ;; Drop the prompt glyph (❯, $, %, ➜ …) and surrounding space.
               (raw  (replace-regexp-in-string ns/prompt-regexp "" raw))
               ;; eat pads double-width (CJK) chars with a trailing space.
               (raw  (replace-regexp-in-string "\\([^\x00-\x7f]\\) " "\\1" raw))
               (text (string-trim raw)))
          (unless (equal text "") text))))))

(defun ns/eat-flush ()
  (ns/send-if-changed (or (ns/eat-get-input) "")))

(defun ns/eat-on-update ()
  "Called by eat-update-hook after every terminal redraw."
  (when ns/enabled
    (when (timerp ns/debounce-timer) (cancel-timer ns/debounce-timer))
    (let ((buf (current-buffer)))
      (setq ns/debounce-timer
            (run-with-timer 0.08 nil
              (lambda ()
                (when (buffer-live-p buf)
                  (with-current-buffer buf
                    (ns/eat-flush)))))))))

(defun ns/on-post-prompt (&rest _)
  "Record input-start and clear HUD when a new shell prompt appears."
  (when (and ns/enabled
             (bound-and-true-p eat-terminal)
             (eat-term-live-p eat-terminal))
    (setq ns/input-start (eat-term-display-cursor eat-terminal))
    (ns/send-if-changed "")))

;;; ── text buffer minor mode ────────────────────────────────────────────────────

(defvar-local ns/text-debounce-timer nil)

(defun ns/text-flush ()
  (ns/send-if-changed (buffer-substring-no-properties (point-min) (point-max))))

(defun ns/text-on-change (&rest _)
  (when (timerp ns/text-debounce-timer) (cancel-timer ns/text-debounce-timer))
  (setq ns/text-debounce-timer (run-with-timer 0.08 nil #'ns/text-flush)))

;;;###autoload
(define-minor-mode native-speaker-mode
  "Stream this buffer's full content to NativeSpeaker on every change."
  :lighter " NS"
  (if native-speaker-mode
      (add-hook 'after-change-functions #'ns/text-on-change nil t)
    (remove-hook 'after-change-functions #'ns/text-on-change t)
    (when (timerp ns/text-debounce-timer) (cancel-timer ns/text-debounce-timer))))

;;; ── eat enable / disable ──────────────────────────────────────────────────────

(defun ns/install-eat-hooks ()
  ;; eat sets inhibit-modification-hooks when rendering, so after-change-functions
  ;; never fires. Use eat-update-hook instead — it runs after every terminal redraw.
  (add-hook 'eat-update-hook #'ns/eat-on-update nil t))

(defun enable-native-speaker ()
  "Enable NativeSpeaker eat tracking and connect."
  (interactive)
  (setq ns/enabled t)
  (advice-add 'eat--post-prompt :after #'ns/on-post-prompt '((name . native-speaker)))
  (ns/connect)
  (add-hook 'eat-mode-hook #'ns/install-eat-hooks)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (derived-mode-p 'eat-mode) (ns/install-eat-hooks))))
  (message "NativeSpeaker: enabled on port %d" ns/port))

(defun disable-native-speaker ()
  "Disable NativeSpeaker eat tracking and close connection."
  (interactive)
  (setq ns/enabled nil)
  ;; Remove all advice this package may have installed (including old versions)
  (advice-remove 'eat--post-prompt  'native-speaker)
  (advice-remove 'eat--send-string  'native-speaker)
  (remove-hook 'eat-mode-hook #'ns/install-eat-hooks)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (derived-mode-p 'eat-mode)
        (remove-hook 'eat-update-hook #'ns/eat-on-update t))))
  (when (timerp ns/debounce-timer) (cancel-timer ns/debounce-timer))
  (ns/disconnect)
  (message "NativeSpeaker: disabled"))

;;; ── Status ────────────────────────────────────────────────────────────────────

(defun reset-native-speaker ()
  "Reload, disable, and re-enable NativeSpeaker in one shot."
  (interactive)
  (disable-native-speaker)
  (load-file (locate-library "init-native-speaker"))
  (enable-native-speaker)
  (message "NativeSpeaker: reset complete"))

(defun native-speaker-status ()
  "Show NativeSpeaker status."
  (interactive)
  (message "NativeSpeaker: %s | eat: %s | port: %d | last: %S"
           (if (and ns/process (process-live-p ns/process)) "connected" "disconnected")
           (if ns/enabled "on" "off")
           ns/port
           (truncate-string-to-width ns/last-sent 50 nil nil "…")))

(with-eval-after-load 'eat
  (enable-native-speaker))

(provide 'init-native-speaker)
;;; init-native-speaker.el ends here
