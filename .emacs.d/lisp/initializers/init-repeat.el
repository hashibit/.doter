;; -*- lexical-binding: t -*-
;; Make M-x repeat ignore movement commands

(defvar my/last-repeatable-command nil
  "Copy of last-repeatable-command that ignores my/repeat-commands-to-ignore")

(defvar my/repeat-commands-to-ignore
  '(my/repeat
    next-line
    end-of-line
    left-char
    right-char
    previous-line
    beginning-of-line
    beginning-of-visual-line

    avy-goto-word-0
    avy-goto-char-in-line
    my-forward-to-word
    backward-word
    my-previous-line
    my-next-line
    my-forward-char-no-cross-line
    my-backward-char-no-cross-line
    mwim-end-of-code-or-line
    mwim-beginning-of-code-or-line
    mwim-end-of-code-or-line
    mwim-beginning-of-code-or-line
    scroll-up-command
    scroll-down-command
    recenter-top-bottom
    scroll-half-page-down
    scroll-half-page-up
    my-save-buffer
    )
  "List of commands for my/last-repeatable-command to ignore.")

(defun my/repeat (repeat-arg)
  "Modified version of repeat that ignore commands in my/repeat-commands-to-ignore."
  (interactive "P")
  (when (null repeat-arg)
    (setq repeat-arg last-prefix-arg))
  (let ((last-repeatable-command my/last-repeatable-command))
    (call-interactively 'repeat t (vector repeat-arg))))

(defun my/save-last-repeatable-command ()
  "Set to last-repeatable-command if value not in my/repeat-commands-to-ignore."
  (if (not
       (member last-repeatable-command my/repeat-commands-to-ignore))
      (setq my/last-repeatable-command last-repeatable-command)))

(add-hook 'pre-command-hook #'my/save-last-repeatable-command)

(keymap-global-set "<remap> <repeat>" #'my/repeat)

(provide 'init-repeat)
