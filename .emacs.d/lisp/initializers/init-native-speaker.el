;;; init-native-speaker.el --- Send buffer content to NativeSpeaker HUD via Unix socket -*- lexical-binding: t -*-
;;
;; Two capture modes:
;;
;;   eat terminal  — tracks input-start (after prompt) to line-end, so cursor
;;                   position (C-b, C-a, C-e) doesn't affect what's captured.
;;                   Enabled automatically when eat loads.
;;
;;   text buffer   — `native-speaker-mode' minor mode; sends the current
;;                   paragraph up to point (debounced) after any change.
;;                   Enable manually in buffers you care about.
;;
;; Uses a Unix-domain socket so no TCP port is occupied.
;; A PID file is checked before connecting so Emacs never hangs on a stale socket.

;;; Code:

(require 'cl-lib)

(defvar my-ns-socket-path "/tmp/nativespeaker.sock"
  "Path to the NativeSpeaker Unix domain socket.")

(defvar my-ns-pid-file "/tmp/nativespeaker.pid"
  "Path written by NativeSpeaker on startup, containing its PID.")

(defvar my-ns-process nil  "Active socket process, or nil.")
(defvar my-ns-enabled  nil "Non-nil when eat tracking is active.")
(defvar my-ns-last-sent ""  "Last string sent; used for diff-check.")
(defvar-local my-ns-debounce-timer   nil "Pending debounce timer (buffer-local).")
(defvar-local my-ns-input-start      nil "Buffer position right after the eat prompt.")

;;; ── Liveness ──────────────────────────────────────────────────────────────────

(defun my-ns-server-alive-p ()
  "Return non-nil if the NativeSpeaker process is running.
Reads the PID file and probes it with `kill -0'."
  (and (file-exists-p my-ns-pid-file)
       (condition-case nil
           (let ((pid (string-to-number
                       (with-temp-buffer
                         (insert-file-contents my-ns-pid-file)
                         (string-trim (buffer-string))))))
             (and (> pid 0)
                  (= 0 (call-process "kill" nil nil nil
                                     "-0" (number-to-string pid)))))
         (error nil))))

;;; ── Connection ────────────────────────────────────────────────────────────────

(cl-defun my-ns-connect ()
  "Open a Unix-domain socket connection to NativeSpeaker.
Returns t on success, nil on failure.  Never blocks — if the server is not
alive the call fails immediately via the PID check."
  (unless (my-ns-server-alive-p)
    (message "NativeSpeaker: server not running (no PID file or process dead)")
    (cl-return-from my-ns-connect nil))
  (condition-case err
      (progn
        (setq my-ns-process
              (make-network-process
               :name     "native-speaker"
               :family   'local
               :service  my-ns-socket-path
               :coding   'utf-8-unix
               :noquery  t           ; don't prompt on Emacs exit
               :sentinel
               (lambda (proc event)
                 (cond
                  ((string-match-p "open" event)
                   (setq my-ns-process proc))
                  ((string-match-p "failed\\|closed\\|deleted" event)
                   (setq my-ns-process nil)
                   (message "NativeSpeaker: %s" (string-trim event)))))))
        t)
    (error
     (message "NativeSpeaker: connect error — %s" (error-message-string err))
     nil)))

(defun my-ns-disconnect ()
  (when (and my-ns-process (process-live-p my-ns-process))
    (delete-process my-ns-process))
  (setq my-ns-process nil))

(defun reconnect-native-speaker ()
  "Drop and re-establish the socket connection to NativeSpeaker."
  (interactive)
  (my-ns-disconnect)
  (if (my-ns-connect)
      (message "NativeSpeaker: reconnecting to %s…" my-ns-socket-path)
    (message "NativeSpeaker: reconnect failed")))

;;; ── Send ──────────────────────────────────────────────────────────────────────

(defun my-ns-send (text)
  "Send TEXT to NativeSpeaker.  No-op if not connected."
  (when (and my-ns-process (process-live-p my-ns-process))
    (condition-case nil
        (process-send-string my-ns-process (concat text "\n"))
      (error (setq my-ns-process nil)))))

(defun my-ns-send-if-changed (text)
  "Send TEXT only when it differs from the last sent value."
  (unless (string= text my-ns-last-sent)
    (setq my-ns-last-sent text)
    (my-ns-send text)))

(defun native-speaker-clear ()
  "Blank the NativeSpeaker HUD."
  (interactive)
  (setq my-ns-last-sent "")
  (my-ns-send "")
  (message "NativeSpeaker: cleared"))

(defun native-speaker-send-region (beg end)
  "Send the active region (or current line) to NativeSpeaker."
  (interactive "r")
  (my-ns-send (string-trim
               (if (use-region-p)
                   (buffer-substring-no-properties beg end)
                 (thing-at-point 'line t)))))

;;; ── eat integration ───────────────────────────────────────────────────────────

(defvar my-ns-prompt-regexp "^\\s-*[❯❮$%#>➜λ»·►▶]+\\s-*"
  "Regexp matching a shell prompt prefix at the start of the input line.")

(defun my-ns-eat-get-input ()
  "Return what the user typed on the current prompt line."
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
               (raw  (replace-regexp-in-string my-ns-prompt-regexp "" raw))
               (raw  (replace-regexp-in-string "\\([^\x00-\x7f]\\) " "\\1" raw))
               (text (string-trim raw)))
          (unless (equal text "") text))))))

(defun my-ns-eat-flush ()
  (my-ns-send-if-changed (or (my-ns-eat-get-input) "")))

(defun my-ns-eat-on-update (&rest _)
  "Called by eat-update-hook after every terminal redraw."
  (when (and my-ns-enabled
             (bound-and-true-p eat-terminal)
             (eat-term-live-p eat-terminal))
    (when (timerp my-ns-debounce-timer) (cancel-timer my-ns-debounce-timer))
    (let ((buf (current-buffer)))
      (setq my-ns-debounce-timer
            (run-with-timer 0.08 nil
                            (lambda ()
                              (when (buffer-live-p buf)
                                (with-current-buffer buf
                                  (my-ns-eat-flush)))))))))

(defun my-ns-on-post-prompt (&rest _)
  "Record input-start and clear HUD when a new shell prompt appears."
  (when (and my-ns-enabled
             (bound-and-true-p eat-terminal)
             (eat-term-live-p eat-terminal))
    (setq my-ns-input-start (eat-term-display-cursor eat-terminal))
    (my-ns-send-if-changed "")))

;;; ── text buffer minor mode ────────────────────────────────────────────────────

(defun my-ns-text-current ()
  "Return text from the start of the current paragraph up to point.
Capped at 1000 chars.  NativeSpeaker extracts the last sentence internally."
  (let* ((end   (point))
         (start (save-excursion
                  (if (re-search-backward "^[[:space:]]*$" nil t)
                      (progn (forward-line 1) (point))
                    (point-min))))
         (text  (buffer-substring-no-properties (min start end) end)))
    (if (> (length text) 1000)
        (substring text (- (length text) 1000))
      text)))

(defvar-local my-ns-text-debounce-timer nil)

(defun my-ns-text-flush ()
  (my-ns-send-if-changed (string-trim (my-ns-text-current))))

(defun my-ns-text-flush-in-buffer (buf)
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (my-ns-text-flush))))

(defun my-ns-text-on-change (&rest _)
  (when (timerp my-ns-text-debounce-timer) (cancel-timer my-ns-text-debounce-timer))
  (setq my-ns-text-debounce-timer
        (run-with-timer 0.5 nil #'my-ns-text-flush-in-buffer (current-buffer))))

;;;###autoload
(define-minor-mode native-speaker-mode
  "Stream current paragraph content to NativeSpeaker on every change."
  :lighter " NS"
  (if native-speaker-mode
      (add-hook 'after-change-functions #'my-ns-text-on-change nil t)
    (remove-hook 'after-change-functions #'my-ns-text-on-change t)
    (when (timerp my-ns-text-debounce-timer) (cancel-timer my-ns-text-debounce-timer))))

;;; ── eat enable / disable ──────────────────────────────────────────────────────

(defun my-ns-install-eat-hooks ()
  (add-hook 'eat-update-hook #'my-ns-eat-on-update nil t))

(defun enable-native-speaker ()
  "Enable NativeSpeaker eat tracking and connect."
  (interactive)
  (setq my-ns-enabled t)
  (advice-add 'eat--post-prompt :after #'my-ns-on-post-prompt '((name . native-speaker)))
  (my-ns-connect)
  (add-hook 'eat-mode-hook #'my-ns-install-eat-hooks)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (derived-mode-p 'eat-mode) (my-ns-install-eat-hooks))))
  (message "NativeSpeaker: enabled (%s)" my-ns-socket-path))

(defun disable-native-speaker ()
  "Disable NativeSpeaker eat tracking and close connection."
  (interactive)
  (setq my-ns-enabled nil)
  (advice-remove 'eat--post-prompt 'native-speaker)
  (advice-remove 'eat--send-string 'native-speaker)
  (remove-hook 'eat-mode-hook #'my-ns-install-eat-hooks)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (derived-mode-p 'eat-mode)
        (remove-hook 'eat-update-hook #'my-ns-eat-on-update t))))
  (when (timerp my-ns-debounce-timer) (cancel-timer my-ns-debounce-timer))
  (my-ns-disconnect)
  (message "NativeSpeaker: disabled"))

;;; ── Status / reset ────────────────────────────────────────────────────────────

(defun reset-native-speaker ()
  "Reload, disable, and re-enable NativeSpeaker in one shot."
  (interactive)
  (disable-native-speaker)
  (load-file (locate-library "init-native-speaker"))
  (enable-native-speaker)
  (message "NativeSpeaker: reset complete"))

(defun native-speaker-status ()
  "Show NativeSpeaker connection and server status."
  (interactive)
  (message "NativeSpeaker: conn=%s server=%s eat=%s socket=%s last=%S"
           (if (and my-ns-process (process-live-p my-ns-process)) "up" "down")
           (if (my-ns-server-alive-p) "alive" "dead")
           (if my-ns-enabled "on" "off")
           my-ns-socket-path
           (truncate-string-to-width my-ns-last-sent 50 nil nil "…")))

;; Auto-enable disabled; run M-x enable-native-speaker manually when needed.
;; (with-eval-after-load 'eat
;;   (enable-native-speaker))

(provide 'init-native-speaker)
;;; init-native-speaker.el ends here