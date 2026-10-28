;; -*- lexical-binding: t -*-
;;; my-editing.el --- Text editing commands

(require 'my-visual-line)
(require 'my-motion)


(defun un-indent-by-removing-4-spaces ()
  "remove 4 spaces from beginning of of line"
  (interactive)
  (save-excursion
    (save-match-data
      (beginning-of-line)
      ;; get rid of tabs at beginning of line
      (when (looking-at "^\\s-+")
        (untabify (match-beginning 0) (match-end 0)))
      (when (looking-at "^    ")
        (replace-match "")))))
(defun increment-number-at-point ()
  (interactive)
  (skip-chars-backward "0-9")
  (or (looking-at "[0-9]+") (error "No number at point"))
  (replace-match
   (number-to-string (1+ (string-to-number (match-string 0))))))
(defun my-delete-to-bol ()
  (interactive)
  (delete-region (line-beginning-position) (point)))

(defun my-delete-to-beginning ()
  (interactive)
  (delete-region (point) (save-excursion (mwim-beginning-of-code-or-line) (point))))

(defun my-delete-to-end ()
  (interactive)
  (delete-region (point) (save-excursion (mwim-end-of-line) (point))))

(defun my-delete-to-eof ()
  (interactive)
  (delete-region (line-beginning-position) (point-max)))
(defun my-yank-but-check-newline-bellow (arg)
  (interactive "p")
  (if (use-region-p)
      (progn
        (delete-region (region-beginning) (region-end))
        (yank))
    (if my-visual-line-selected
        (progn
          (line-move 1)
          (beginning-of-line)
          (yank arg)
          ;; 末尾有一个换行，光标要往回走一下
          (backward-char 1))
      (yank arg))))

(defun my-yank-but-check-newline-above (arg)
  (interactive "p")
  (if (use-region-p)
      (progn
        (delete-region (region-beginning) (region-end))
        (yank))
    (if my-visual-line-selected
        (progn
          (beginning-of-line)
          (yank arg)
          ;; 末尾有一个换行，光标要往回走一下
          (backward-char 1))
      (yank arg))))
(defun upcase-p(str) (string= str (upcase str)))

(defun downcase-p(str) (string= str (downcase str)))


(defun my-toggle-case-char ()
  (interactive)
  (if (region-active-p)
      (let* ((i 0)
             (start (region-beginning))
             (end (region-end))
             (return-string "")
             (input (buffer-substring-no-properties start end)))
                                        ; (message "input-string: %s" input)
        (while (< i (- end start))
          (let ((current-char (substring input i (+ i 1))))
                                        ; (message "current-char: %s, is downcase? %s" current-char (downcase-p current-char))
            (if (downcase-p current-char)
                (setq return-string
                      (concat return-string (upcase current-char)))
              (setq return-string
                    (concat return-string (downcase current-char)))))
          (setq i (+ i 1)))
        (delete-region (region-beginning) (region-end))
        (insert return-string)
        ;; select the region again
        (goto-char start)
        (set-mark-command nil)
        (goto-char end)
        (setq deactivate-mark nil))
    (let* ((current-char (buffer-substring-no-properties (point) (+ 1 (point))))
           (upcased (upcase-p current-char))
           (f (if upcased 'downcase-region 'upcase-region)))
                                        ; (message "input: %s" current-char)
      (funcall f (point) (+ 1 (point)))
      (forward-char))))
(defun my-comment-region-or-line()
  (interactive)
  (if (region-active-p)
      (let ((beg (save-excursion (goto-char (region-beginning))
                                 (line-beginning-position)))
            (end (save-excursion (goto-char (region-end))
                                 ;; if is V mode, i.e. selection lines, then ignore last line.
                                 (if (bolp) (region-end)
                                   (line-end-position)))))
        (comment-or-uncomment-region beg end))
    (comment-line 1)))
(defun my-delete-char-or-kill-region (arg)
  (interactive "p")
  (if (use-region-p)
      (kill-region (region-beginning) (region-end))
    (delete-char (or arg 1))))

(defun my-kill-whole-line-or-kill-region (arg)
  (interactive "p")
  (if (use-region-p)
      (kill-region (region-beginning) (region-end))
    (kill-whole-line (or arg 1))))


(defun my-set-mark-command-or-deactivate-mark (_arg)
  (interactive "p")
  (if (use-region-p)
      (deactivate-mark)
    (push-mark nil nil t)))
(defun my-replace-char ()
  "delete current char, goto insert mode"
  (interactive)
  (delete-char 1)
  ;; (call-interactively (key-binding (kbd "q")))
  (my-quit-god-mode))
(defun my-join-lines (&optional _arg)
  "Join lines in region, or join the following line to this one."
  (interactive "p")
  (if (use-region-p)
      (delete-indentation nil (region-beginning) (region-end))
    (delete-indentation t)))
(defun my-kill-word()
  (interactive)
  (let ((start (point)))
    (my-forward-to-word)
    (delete-region start (point))))
(defun my-break-to-multiple-lines(arg)
  (interactive "*P")
  (if (derived-mode-p 'eat-mode)
      ;; (claude-code--eat-send-alt-return)
      (eat-self-input 1 ?\n)
    (sp-split-sexp arg)
    (insert-char ?+)
    (newline-and-indent)))


(provide 'my-editing)
