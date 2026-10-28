;; -*- lexical-binding: t -*-
;;; init-terminal-notifier.el --- Terminal-notifier configuration

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Terminal notifier 
;; requires 'sudo port install terminal-notifier'
;; stolen from erc-notifier
;;
;; (my-terminal-notifier-notify "Emacs notification"
;;                           "Something amusing happened")

;;; Code:

(defvar my-terminal-notifier-command
  (executable-find "terminal-notifier")
  "The path to terminal-notifier.")

(defun my-terminal-notifier-notify (title message)
  "Show a message with `my-terminal-notifier-command`."
  (start-process "terminal-notifier"
                 "*terminal-notifier*"
                 my-terminal-notifier-command
                 "-title" title
                 "-message" message
                 "-activate" "org.gnu.Emacs"
                 "-sender" "org.gnu.Emacs"))

(defun my-timed-notification (time msg)
  "Show the notification MSG at TIME."
  (interactive
   "sNotification when (e.g: 2 minutes, 60 seconds, 3 days): \nsMessage: ")
  (run-at-time time
               nil
               (lambda (msg) (my-terminal-notifier-notify "Emacs" msg))
               msg))

;; Old names, so M-x with the old name still works.
(define-obsolete-function-alias 'timed-notification #'my-timed-notification "2026-10-27")

(provide 'init-terminal-notifier)

;;; init-terminal-notifier.el ends here
