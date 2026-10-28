;; -*- lexical-binding: t -*-
;;; init-exec-path.el --- PATH for programs that Emacs runs

;;; Commentary:
;;
;;  A GUI Emacs started from the Dock gets a minimal PATH.
;;  Set the PATH by hand here. Do not ask zsh: that costs time at startup.
;;  Add a directory to `my-exec-path-dirs' when you install a new tool.
;;

;;; Code:

(defconst my-exec-path-dirs
  (mapcar #'expand-file-name
    '("~/.local/bin"
       "/opt/homebrew/bin"
       "/opt/homebrew/sbin"
       "/usr/local/bin"))
  "Directories to put before the inherited PATH, in this order.")

;; PATH is for subprocesses (shells, compile). `exec-path' is for Emacs.
(setenv "PATH"
  (string-join
    (delete-dups (append my-exec-path-dirs
                   (split-string (or (getenv "PATH") "") path-separator t)))
    path-separator))
(setq exec-path (append (split-string (getenv "PATH") path-separator t)
                  (list exec-directory)))

;; Old way: copy PATH from a zsh login shell. It costs 0.1-0.4s at startup.
;; (use-package exec-path-from-shell
;;   :init (setq exec-path-from-shell-arguments '("-l"))
;;   :config (exec-path-from-shell-initialize))

(provide 'init-exec-path)

;;; init-exec-path.el ends here
