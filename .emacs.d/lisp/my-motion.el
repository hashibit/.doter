;; -*- lexical-binding: t -*-
;;; my-motion.el --- Cursor motion commands

(require 'my-visual-line)


(defun my-move-to-end-of-word ()
  "Move to the next \"last character\" of a word."
  (interactive)
  (forward-char)
  (re-search-forward "\\w\\b" nil t)
  (goto-char (match-beginning 0)))
(defun my-goto-match-paren (_arg)
  "Go to the matching parenthesis using show-paren-data-function when
  available (works with tree-sitter modes), else fall back to syntax table."
  (interactive "p")
  (let ((data (when (and (boundp 'show-paren-data-function)
                         show-paren-data-function)
                (funcall show-paren-data-function))))
    (if (and data (nth 2 data) (not (nth 4 data)))
        ;; data = (here-beg here-end there-beg there-end mismatch)
        (progn
          (goto-char (nth 2 data))
          ;; If we jumped to a close paren, move past it so the next call
          ;; sees it as char-before and can toggle back correctly.
          (when (eq (syntax-class (syntax-after (point))) 5)
            (forward-char 1)))
      ;; fallback: syntax-table based
      (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
            (t
             (backward-char 1)
             (cond ((looking-at "\\s\)")
                    (forward-char 1) (backward-list 1))
                   (t
                    (while (not (looking-at "\\s("))
                      (backward-char 1)
                      (cond ((looking-at "\\s\)")
                             (forward-char 1)
                             (backward-list 1)
                             (backward-char 1))))))))))); ))
(defun my-next-line-or-mc/mark-next-like-this (arg)
  (interactive "p")
  (if (use-region-p)
      (my-mc/mark-next-like-this arg)
    (line-move 1)))

(defun my-prev-line-or-mc/mark-next-like-this (arg)
  (interactive "p")
  (if (use-region-p)
      (my-mc/mark-previous-like-this
       arg)
    (line-move -1)))
(defun my-is-beginning-of-line ()
  (interactive)
  (bolp))


(defun my-is-end-of-line ()
  (interactive)
  (eolp))
(defun my-forward-char-no-cross-line ()
  (interactive)
  (unless (eolp)
    (forward-char)))

(defun my-forward-to-word ()
  (interactive)
  (let* ((pos-before (point))
         (pos-after (save-excursion
                      (forward-to-word 1)
                      (point)))
         (sub-string (buffer-substring
                      pos-before
                      pos-after)))
    ;; NOTE: the ] must be first char in the regex candicates. see https://www.gnu.org/software/emacs/manual/html_node/emacs/Regexps.html
    (if-let* ((distance (string-match-p "[])}([{&=\/\*\:\"\,\.\~\?\<\>]" sub-string)))
        (progn
          ;; if next char is special then find next regular char, because forward 0 distance is meaningless
          (when (= distance 0)
            (setq distance (string-match-p "[^])}([{&=\/\*\:\"\,\.\~\?\s\<\>]" sub-string)))
          ;; if all chars are special chars, then just do forward-to-word.
          (if distance
              (forward-char distance)
            (forward-to-word 1)))
      (forward-to-word 1))))
(defun my-next-line(_args)
  (interactive "p")
  (setq this-command 'next-line)
  (if my-visual-line-selection
      (let ((curr-line (line-number-at-pos)))
        (cond
         ((< curr-line my-visual-line-start-num)
          (end-of-line 2)
          (beginning-of-line))
         ((= curr-line my-visual-line-start-num)
          (goto-char (point-min))
          (forward-line (1- my-visual-line-start-num))
          (set-mark-command nil)
          (end-of-line 2))
         (t
          (end-of-line 2))))
    (line-move 1)))

(defun my-previous-line(_args)
  (interactive "p")
  (setq this-command 'previous-line)
  (if my-visual-line-selection
      (let ((curr-line (line-number-at-pos)))
        (cond
         ((> curr-line my-visual-line-start-num)
          (line-move -1)
          (end-of-line))
         ((= curr-line my-visual-line-start-num)
          (goto-char (point-min))
          (forward-line (1- my-visual-line-start-num))
          (end-of-line)
          (set-mark-command nil)
          (line-move -1)
          (beginning-of-line))
         (t
          (line-move -1)
          (beginning-of-line))))
    (line-move -1)))
(defun my-backward-char-no-cross-line ()
  (interactive)
  (unless (bolp)
    (backward-char)))
(defun my-find-char-forward (char)
  "Move point to the next occurrence of CHAR on the current line."
  (interactive (list (read-char "Find char: ")))
  (let ((pos (search-forward (char-to-string char) (line-end-position) t)))
    (if pos
        (goto-char pos)
      (message "Character `%c' not found in this line." char))))

(defun my-find-char-backward (char)
  "Move point to the previous occurrence of CHAR on the current line."
  (interactive (list (read-char "Find char backwards: ")))
  (let ((pos (search-backward (char-to-string char) (line-beginning-position) t)))
    (if pos
        (goto-char pos)
      (message "Character `%c' not found in this line." char))))
(defun my-scroll-cursor-down ()
  (interactive)
  (line-move (/ (window-height (selected-window)) 2)))

(defun my-scroll-cursor-up ()
  (interactive)
  (line-move (- (/ (window-height (selected-window)) 2))))


(provide 'my-motion)
