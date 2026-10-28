;; -*- lexical-binding: t -*-
;;; init-exec-path.el --- PATH from the login shell

;;; Commentary:
;;
;;  Copy PATH from zsh into Emacs. This costs about 0.4s at startup.
;;  Keep the interactive shell: PATH is set in .zshrc.
;;

;;; Code:

(use-package exec-path-from-shell
  :config (exec-path-from-shell-initialize))

(provide 'init-exec-path)

;;; init-exec-path.el ends here
