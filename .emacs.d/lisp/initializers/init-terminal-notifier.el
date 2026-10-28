;; -*- lexical-binding: t -*-
;;; init-terminal-notifier.el --- Terminal-notifier configuration

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Terminal notifier 
;; requires 'sudo port install terminal-notifier'
;; stolen from erc-notifier
;;
;; (terminal-notifier-notify "Emacs notification"
;;                           "Something amusing happened")

;;; Code:

(defvar terminal-notifier-command
  (executable-find "terminal-notifier")
  "The path to terminal-notifier.")

(defun terminal-notifier-notify (title message)
  "Show a message with `terminal-notifier-command`."
  (start-process "terminal-notifier"
                 "*terminal-notifier*"
                 terminal-notifier-command
                 "-title" title
                 "-message" message
                 "-activate" "org.gnu.Emacs"
                 "-sender" "org.gnu.Emacs"))

(defun timed-notification (time msg)
  "Show the notification MSG at TIME."
  (interactive
   "sNotification when (e.g: 2 minutes, 60 seconds, 3 days): \nsMessage: ")
  (run-at-time time
               nil
               (lambda (msg) (terminal-notifier-notify "Emacs" msg))
               msg))

(provide 'init-terminal-notifier)

;;; init-terminal-notifier.el ends here
