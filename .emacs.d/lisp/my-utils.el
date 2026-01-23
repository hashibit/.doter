;; -*- lexical-binding: t -*-
;;; my-utils.el --- Personal utility functions

(require 'f)


(defun my-util-split-long-line-to-sub-lines (long-line wrap-width)
  "Split LONG-LINE into sub-lines with WRAP-WIDTH."
  (interactive)
  (let ((total-len (string-width long-line))
         (idx 0)
         (collected ()))
    (while (> (- total-len idx) wrap-width)
      (push (substring long-line idx (+ idx wrap-width)) collected)
      (setq idx (+ idx wrap-width)))
    (when (< idx total-len)
      (push (substring long-line idx total-len) collected))
    (reverse collected)))

;; (message "%s" (my-util-split-long-line-to-sub-lines "It is useful to include newlines" 4))
;; (string-width "It is useful to include newlines")

(defun my-util-seperate-string (line max-length)
  "Separate LINE into chunks of MAX-LENGTH."
  (let ((remains line)
         (result-lines ())
         )
    (while (> (length remains) max-length)
      (push (substring remains 0 max-length) result-lines)
      (setq remains (substring remains max-length nil))
      )
    ;; last one
    (push remains result-lines)
    (reverse result-lines)
    )
  )




(defun my-util-read-fmt-content (filepath)
  "Read and format content from FILEPATH."
  (interactive)
  (let ((file-content (f-read-text filepath)))
    (with-temp-buffer
      (emacs-lisp-mode)
      ;; (rename-buffer "tmp.el" t)
      ;; (set-auto-mode)
      ;; (message "%s" (buffer-mode))
      (insert file-content)
      (font-lock-ensure)
      (buffer-string))))



;; ;; copy from elisp-eldoc-var-docstring-with-value
;; (defun my-elisp-eldoc-var-docstring-with-value (callback &rest _)
;;   (when-let ((cs (elisp--current-symbol)))
;;     (when (and (boundp cs)
;; 	           ;; nil and t are boundp!
;; 	           (not (null cs))
;; 	           (not (eq cs t)))
;;       (funcall callback
;; 	           (format "%s"
;; 		               (let* ((doc
;;                                (describe-function cs)
;;                                ;; (documentation-property
;;                                ;;      cs 'variable-documentation t)
;;                                )
;; 			                  (more (- (length doc) 1000)))
;;                          (message "doc: %s" doc)
;; 			             (concat (propertize
;; 				                  (string-limit (if (string= doc "nil")
;; 						                            "Undocumented."
;; 						                          doc)
;; 					                            1000)
;; 				                  'face 'font-lock-doc-face)
;; 				                 (when (> more 0)
;; 				                   (format "[%sc more]" more)))))
;; 	           :thing cs
;; 	           :face 'font-lock-variable-name-face))))



(defun which-active-modes ()
  "Give a message of which minor modes are enabled in the current buffer."
  (interactive)
  (let ((active-modes))
    (mapc
      (lambda (mode)
        (condition-case nil
          (if (and (symbolp mode) (symbol-value mode))
            (add-to-list 'active-modes mode))
          (error nil)))
      minor-mode-list)
    (message "Active modes are %s" active-modes)))




;; Check if system is Darwin/Mac OS X
(defun my-system-type-is-darwin ()
  "Return true if system is darwin-based (Mac OS X)"
  (string-equal system-type "darwin"))

;; Check if system is Microsoft Windows
(defun my-system-type-is-windows ()
  "Return true if system is Windows-based (at least up to Win7)"
  (string-equal system-type "windows-nt"))

;; Check if system is GNU/Linux
(defun my-system-type-is-gnu ()
  "Return true if system is GNU/Linux-based"
  (string-equal system-type "gnu/linux"))




(defun bf-pretty-print-xml-region (begin end)
  "Pretty format XML markup in region. You need to have nxml-mode
    http://www.emacswiki.org/cgi-bin/wiki/NxmlMode installed to do
    this.  The function inserts linebreaks to separate tags that have
    nothing but whitespace between them.  It then indents the markup
    by using nxml's indentation rules."
  (interactive "r")
  (save-excursion
    (nxml-mode)
    (goto-char begin)
    (while (search-forward-regexp "\>[ \\t ]*\<" nil t)
      (backward-char)
      (insert "\n")
      (setq end (1+ end)))
    (indent-region begin end))
  (message "Ah, much better!"))




(defun my-most-recent-normal-buffer()
  "Return the most recent normal buffer."
  (interactive)
  (let ((bufs (seq-filter
                (lambda(elt) (my-god-this-is-normal-editor-buffer (buffer-name elt)))
                (buffer-list))))
    (when (length> bufs 1)
      (nth 1 bufs))))



(defun flip-buffer-to-window ()
  "Flip to the last-visited buffer in this window."
  (interactive)
  (let ((recent (my-most-recent-normal-buffer)))
    (switch-to-buffer (or recent (other-buffer (current-buffer)))))
  )



(defun json-to-single-line (beg end)
  "Collapse prettified json in region between BEG and END to a single line"
  (interactive "r")
  (if (use-region-p)
    (save-excursion
      (save-restriction
        (narrow-to-region beg end)
        (goto-char (point-min))
        (while (re-search-forward "[[:space:]\n]+" nil t)
          (replace-match " "))))
    (print "This function operates on a region")))


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





(defun my-show-file-name ()
  "Show the current buffer's file name."
  (interactive)
  (message (buffer-file-name)))




(defun my-copied-content-is-end-of-newline ()
  "Check if copied content ends with newline."
  (interactive)
  (string-suffix-p "\n" (current-kill 0 'DONT-MOVE)))




(defun buffer-mode (&optional buffer-or-name)
  "Returns the major mode associated with a buffer.
If buffer-or-name is nil return current buffer's mode."
  (with-current-buffer
    (if buffer-or-name
      (get-buffer buffer-or-name)
      (current-buffer))
    major-mode))



;; Source: https://www.emacswiki.org/emacs/misc-cmds.el
(defun my-revert-buffer-no-confirm ()
  "Revert buffer without confirmation."
  (interactive)
  (revert-buffer :ignore-auto :noconfirm)
  (refresh-current-mode))



(defun increment-number-at-point ()
  (interactive)
  (skip-chars-backward "0-9")
  (or (looking-at "[0-9]+") (error "No number at point"))
  (replace-match
    (number-to-string (1+ (string-to-number (match-string 0))))))




(defun my-move-to-end-of-word ()
  "Move to the next 'last character' of a word."
  (interactive)
  (forward-char)
  (re-search-forward "\\w\\b" nil t)
  (goto-char (match-beginning 0)))

(defun my-delete-to-bol (args)
  (interactive "p")
  (set-mark-command nil)
  (beginning-of-line)
  (delete-region (region-beginning) (region-end)))

(defun my-delete-to-beginning (args)
  (interactive "p")
  (set-mark-command nil)
  (mwim-beginning-of-code-or-line)
  (delete-region (region-beginning) (region-end)))

(defun my-delete-to-end (args)
  (interactive "p")
  (set-mark-command nil)
  (mwim-end-of-line)
  (delete-region (region-beginning) (region-end)))

(defun my-delete-to-eof (args)
  (interactive "p")
  (set-mark-command nil)
  (forward-line 0)
  (set-mark-command nil)
  (end-of-buffer)
  (delete-region (region-beginning) (region-end)))



(defun my-yank-but-check-newline-bellow (arg)
  (interactive "p")
  (if (use-region-p)
    (let ((beg (region-beginning))
           (end (copy-marker (region-end))))
      (delete-region beg end)
      (yank))
    (if my-visual-line-selected
      (progn
        (next-line)
        (beginning-of-line)
        (yank arg)
        ;; 末尾有一个换行，光标要往回走一下
        (backward-char 1))
      (yank arg))))

(defun my-yank-but-check-newline-above (arg)
  (interactive "p")
  (if (use-region-p)
    (let ((beg (region-beginning))
           (end (copy-marker (region-end))))
      (delete-region beg end)
      (yank))
    (if my-visual-line-selected
      (progn
        (beginning-of-line)
        (yank arg)
        ;; 末尾有一个换行，光标要往回走一下
        (backward-char 1))
      (yank arg))))




(defun my-hs-toggle-all ()
  "If anything isn't hidden, run `hs-hide-all', else run `hs-show-all'."
  (interactive)
  (hs-minor-mode 1)
  (let ((starting-ov-count
          (length (overlays-in (point-min) (point-max)))))
    (if (derived-mode-p 'c++-mode)
      (save-excursion
        (goto-char (point-min))
        (re-search-forward "namespace.*?{" nil t)
        (next-line)
        (hs-hide-level 1))
      (hs-hide-all))
    (when (equal
            (length (overlays-in (point-min) (point-max)))
            starting-ov-count)
      (hs-show-all)
      (recenter))))

(defun my-hs-toggle-hiding ()
  (interactive)
  (hs-minor-mode 1)
  (if (hs-already-hidden-p)
    (hs-show-block)
    (hs-hide-block)))

(defun my-hide-all ()
  (interactive)
  (hs-minor-mode 1)
  (hs-hide-all))

;; (add-hook 'prog-mode-hook 'my-hide-all)



(defun my-M-x ()
  (interactive)
  (counsel-M-x))

(defun my-occur ()
  (interactive)
  (if (region-active-p)
    (let* ((start (region-beginning))
            (end (region-end))
            (input (buffer-substring-no-properties start end)))
      (deactivate-mark)
      (counsel-grep input))
    (counsel-grep)))

(defun my-rg-at-point ()
  (interactive)
  (if (region-active-p)
    (let* ((start (region-beginning))
            (end (region-end))
            (input (buffer-substring-no-properties start end)))
      (deactivate-mark)
      (counsel-rg (concat input " ")))
    (counsel-rg)))

(defun my-find-files ()
  (interactive)
  (counsel-find-file))

(defun my-mark-ring ()
  (interactive)
  (counsel-mark-ring))



(advice-add 'my-M-x :before (lambda (&rest r) (refresh-current-mode))
                                        ; convenient name for identifying or removing this advice later
  '((name . "my-god-mode-before-m-x")))

(advice-add 'my-mark-ring :after (lambda (&rest r) (recenter))
                                        ; convenient name for identifying or removing this advice later
  '((name . "recenter-after-mark-ring")))




;; delete all other buffers, only keep current one.
(defun my-only-current-buffer ()
  "Kill all non-star other buffers."
  (interactive)
  (let ((orig-eglot-active (bound-and-true-p eglot--managed-mode)))
    (ignore-errors (eglot-shutdown-all))
    (mapc 'kill-buffer (delq
                         (current-buffer)
                         (remove-if-not 'buffer-file-name (buffer-list)))) ;; this keep * buffers alive
    (if (bound-and-true-p centaur-tabs-mode)
      (centaur-tabs-kill-other-buffers-in-current-group))
    (if orig-eglot-active (eglot-ensure))))

;; delete all other buffers, only keep current one.
(defun my-only-current-buffer-include-specials ()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer (delq
                       (current-buffer)
                       (buffer-list))) ;; this destroy * buffers too
  (if (bound-and-true-p centaur-tabs-mode)
    (centaur-tabs-kill-other-buffers-in-current-group))
  (if (bound-and-true-p global-eldoc-mode)
    (eldoc-box-reset-frame))
  (treemacs-find-file)
  )




(defun my-joindirs (root &rest dirs)
  "Joins a series of directories together, like Python's os.path.join,
  (dotemacs-joindirs \"/tmp\" \"a\" \"b\" \"c\") => /tmp/a/b/c"
  (if (not dirs)
    root
    (apply 'joindirs (expand-file-name (car dirs) root) (cdr dirs))))




(defun bury-compile-buffer-if-successful (buffer string)
  "Bury a compilation buffer if succeeded without warnings "
  (when (and
          (buffer-live-p buffer)
          (string-match "compilation" (buffer-name buffer))
          (string-match "finished" string)
          ;; (not
          ;;   (with-current-buffer buffer
          ;;     (goto-char (point-min))
          ;;     (search-forward "warning" nil t)))
          )
    (run-with-timer 1 nil
      (lambda (buf)
        (delete-windows-on buf)
        (bury-buffer buf)
        ;; (switch-to-prev-buffer (get-buffer-window buf) 'kill)
        )
      buffer)))


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




(defun my-goto-match-paren (arg)
  "Go to the matching parenthesis if on parenthesis. Else go to the
  opening parenthesis one level up."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1))
    (t
      (backward-char 1)
      (cond ((looking-at "\\s\)")
              (forward-char 1) (backward-list 1))
        (t
          (while (not (looking-at "\\s("))
            (backward-char 1)
            (cond ((looking-at "\\s\)")
                    (message "->> )")
                    (forward-char 1)
                    (backward-list 1)
                    (backward-char 1)))
            ))))))


(defun my-comment-region-or-line()
  (interactive)
  (if (region-active-p)
    (let ((beg (save-excursion (goto-char (region-beginning))
                 (line-beginning-position)))
           (end (save-excursion (goto-char (region-end))
                  ;; if is V mode, i.e. selection lines, then ignore last line.
                  (if (bolp) (region-end)
                    (line-end-position))
                  )))
      (comment-or-uncomment-region beg end))
    (comment-line 1)))




(defun my-delete-char-or-kill-region (arg)
  (interactive "p")
  (if (use-region-p)
    (let ((beg (region-beginning))
           (end (copy-marker (region-end))))
      (kill-region beg end))
    (delete-forward-char (or arg 1))))

(defun my-kill-whole-line-or-kill-region (arg)
  (interactive "p")
  (if (use-region-p)
    (let ((beg (region-beginning))
           (end (copy-marker (region-end))))
      (kill-region beg end))
    (kill-whole-line (or arg 1))))


(defun my-set-mark-command-or-deactivate-mark (arg)
  (interactive "p")
  (if (use-region-p)
    (deactivate-mark)
    (push-mark nil nil t)))


(defun my-next-line-or-mc/mark-next-like-this (arg)
  (interactive "p")
  (if (use-region-p)
    (my-mc/mark-next-like-this arg)
    (next-line)))

(defun my-prev-line-or-mc/mark-next-like-this (arg)
  (interactive "p")
  (if (use-region-p)
    (my-mc/mark-previous-like-this
      arg)
    (previous-line)))


(defun my-replace-char ()
  "delete current char, goto insert mode"
  (interactive)
  (delete-forward-char 1)
  ;; (call-interactively (key-binding (kbd "q")))
  (my-quit-god-mode))


(defun my-save-buffer ()
  "delete current word, goto insert mode"
  (interactive)
  (save-buffer)
  (refresh-current-mode)
  ;; (my-quit-mc-mode-if-need)
  )

(defun my-save-buffer-without-hooks ()
  "delete current word, goto insert mode"
  (interactive)
  (save-buffer-without-hooks)
  (refresh-current-mode)
  ;; (my-quit-mc-mode-if-need)
  )


(setq my-visual-line-selection nil)
(setq my-visual-line-start-num nil)
(setq my-visual-line-selected nil)


(defun my-set-visual-selected(&rest r)
  (setq my-visual-line-selected t))
;; kill-whole-line 不会触发 deactivate mark，所以我们手动设置 visual-line 模式
(advice-add 'kill-whole-line :after #'my-set-visual-selected)


(defun my-kill-ring-save-advice (orig-fun &rest args)
  (let ((result (apply orig-fun args))) ; 先执行原始的 kill-ring-save
    ;; 如果是 visual line selection 模式，则在复制的内容最后，加上一个换行符
    (when (and my-visual-line-selection
            (stringp (car kill-ring)))
      (let ((current-text (car kill-ring)))
        (setcar kill-ring (concat current-text "\n"))
        ))
    result))
(advice-add 'kill-ring-save :around #'my-kill-ring-save-advice)

;; 这个会在最后执行，所以做清理动作
(add-hook 'deactivate-mark-hook
  (lambda ()
    (if my-visual-line-selection
      (setq my-visual-line-selected t)
      (setq my-visual-line-selected nil))
    (setq
      my-visual-line-selection nil
      my-visual-line-start-num nil)))


(defun my-copy-whole-line-or-region ()
  "智能复制：有选区则复制选区（支持 visual-line），无选区则复制当前行。"
  (interactive)
  (if (use-region-p)
    ;; 有选区：直接调用 kill-ring-save（会触发 advice 加换行）
    (call-interactively #'kill-ring-save)
    ;; 无选区：手动复制当前行
    ;; 标记这是一个行选择
    (setq my-visual-line-selected t)
    (save-excursion
      (copy-region-as-kill (line-beginning-position) (line-end-position)))
    ;; copy-region-as-kill 不会触发 kill-ring-save advice
    ;; 所以我们手动加换行
    (when (stringp (car kill-ring))
      (kill-new (concat (car kill-ring) "\n")))
    (message "Copied line")))


(defun my-copy-whole-line-or-region-to-tmux ()
  "Copy the current region or whole line to tmux paste buffer."
  (interactive)
  (let* ((in-region (use-region-p))
         (beg (if in-region (region-beginning) (line-beginning-position)))
         (end (if in-region (region-end) (min (1+ (line-end-position) ) (point-max)))))
    (shell-command-on-region beg end "tmux load-buffer -" nil nil t)
    (message "Copied to tmux buffer")))


(defun my-select-current-line-and-forward-line (arg)
  "Select the current line and move the cursor by ARG lines IF
  no region is selected.
  If a region is already selected when calling this command, only move
  the cursor by ARG lines."
  (interactive "p")
  (setq my-visual-line-selection t)
  (if (use-region-p)
    (let* ((curr-line (line-number-at-pos))
            (beg (region-beginning))
            (beg-line (line-number-at-pos beg))
            (end (region-end))
            (end-line (line-number-at-pos end)))
      (cond
        ((eq curr-line beg-line)
          (setq my-visual-line-start-num end-line)
          (goto-char end)
          (end-of-line)
          (set-mark-command nil)
          (goto-char beg)
          (beginning-of-line)
          )
        ((eq curr-line end-line)
          (setq my-visual-line-start-num beg-line)
          (goto-char beg)
          (beginning-of-line)
          (set-mark-command nil)
          (goto-char end)
          (end-of-line)
          )
        )
      )
    (setq my-visual-line-start-num (line-number-at-pos))
    (beginning-of-line)
    (set-mark-command nil)
    (end-of-line)))


(defun my-join-lines (arg)
  "Apply join-line over region."
  (interactive "p")
  (forward-line 0)
  ;; goto line begin
  (if (use-region-p)
    (let ((beg (region-beginning))
           (end (copy-marker (region-end))))
      (goto-char beg)
      (while (< (point) end)
        (join-line 1)))
    (progn
      (set-mark-command nil)
      (end-of-line)
      (join-line -1))))


(defun my-is-beginning-of-line ()
  (interactive)
  (= (point)
    (line-beginning-position)))


(defun my-is-end-of-line ()
  (interactive)
  (= (point) (line-end-position)))


(defun my-enlarge-half-height ()
  "Expand current window to use half of the other window's lines."
  (interactive)
  (enlarge-window
    (/ (window-body-height) 4)))

(defun my-enlarge-half-width ()
  "Expand current window to use half of the other window's lines."
  (interactive)
  (enlarge-window-horizontally
    (/ (window-body-width) 4)))

(defun my-shrink-half-height ()
  "Expand current window to use half of the other window's lines."
  (interactive)
  (shrink-window
    (/ (window-body-height) 4)))

(defun my-shrink-half-width ()
  "Expand current window to use half of the other window's lines."
  (interactive)
  (shrink-window-horizontally
    (/ (window-body-width) 4)))

(defun my-enarge-window-height()
  (interactive)
  (enlarge-window 1000))


(defun my-forward-char-no-cross-line ()
  (interactive)
  (unless (my-is-end-of-line)
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
    (if-let ((distance (string-match-p "[])}([{&=\/\*\:\"\,\.\~\?\<\>]" sub-string)))
      (progn
        ;; if next char is special then find next regular char, because forward 0 distance is meaningless
        (when (= distance 0)
          (setq distance (string-match-p "[^])}([{&=\/\*\:\"\,\.\~\?\s\<\>]" sub-string)))
        ;; if all chars are special chars, then just do forward-to-word.
        (if distance
          (forward-char distance)
          (forward-to-word 1)))
      (forward-to-word 1))))

(defun my-next-line(args)
  (interactive "p")
  (if my-visual-line-selection
    (let ((curr-line (line-number-at-pos)))
      (cond
        ((< curr-line my-visual-line-start-num)
          (end-of-line 2)
          (beginning-of-line))
        ((= curr-line my-visual-line-start-num)
          (goto-line my-visual-line-start-num)
          (beginning-of-line)
          (set-mark-command nil)
          (end-of-line 2))
        (t
          (end-of-line 2))))
    (next-line)))

(defun my-previous-line(args)
  (interactive "p")
  (if my-visual-line-selection
    (let ((curr-line (line-number-at-pos)))
      (cond
        ((> curr-line my-visual-line-start-num)
          (previous-line)
          (end-of-line)
          )
        ((= curr-line my-visual-line-start-num)
          (goto-line my-visual-line-start-num)
          (end-of-line)
          (set-mark-command nil)
          (previous-line)
          (beginning-of-line)
          )
        (t
          (previous-line)
          (beginning-of-line)
          )
        ))
    (previous-line)))

(defun my-kill-word()
  (interactive)
  (push-mark nil nil t)
  (my-forward-to-word)
  (backward-delete-char-untabify 1)
  )

(defun my-backward-char-no-cross-line ()
  (interactive)
  (unless (my-is-beginning-of-line)
    (backward-char)))



(defun my-quit-other-window()
  (interactive)
  (delete-other-windows)
  (ignore-errors
    (when (my-imenu-list-check-window-is-open) (imenu-list-quit-window)))
  ;; (ignore-errors
  ;;   (when (eq (treemacs-current-visibility) 'visible) (delete-window (treemacs-get-local-window))))
  (keyboard-quit))



(defun my-quit-other-buffer ()
  "Function to quit help in other-window."
  (interactive)
  (unless (one-window-p)
    (save-excursion
      (let ((next 1))
        (other-window next)
        (quit-window)
        ))))



(defun my-toggle-eldoc-box-help-at-point ()
  (interactive)

  ;; always use my-term-popup
  ;; (if my-term-popup-show-p
  ;;     (my-term-popup-close)
  ;;   (show-eldoc-popup-at-point))

  (if (display-graphic-p)
    ;; graphic, use eldoc-box
    (if (and (bound-and-true-p eldoc-box--frame)
          (frame-live-p eldoc-box--frame)
          (frame-visible-p eldoc-box--frame))
      (eldoc-box-quit-frame)
      (eldoc-box-help-at-point))
    ;; terminal tui, use my-term-popup
    (if my-term-popup-show-p
      (my-term-popup-close)
      (show-eldoc-popup-at-point)))
  )




(defun my-break-to-multiple-lines(arg)
  (interactive "*P")
  (sp-split-sexp arg)
  (insert-char ?+)
  (newline-and-indent)
  )



(defun my-blink-search()
  (interactive)
  (blink-search-restart-process)
  (blink-search))


(defun advise-once (symbol where function &optional props)
  (advice-add symbol :after `(lambda (&rest _) (advice-remove ',symbol ',function)))
  (advice-add symbol where function props))



(defun upward-find-file (filename &optional startdir)
  "Move up directories until we find a certain filename. If we
  manage to find it, return the containing directory. Else if we
  get to the toplevel directory and still can't find it, return
  nil. Start at startdir or . if startdir not given"

  (let ((dirname (expand-file-name
		           (if startdir startdir ".")))
	     (found nil) ; found is set as a flag to leave loop if we find it
	     (top nil))  ; top is set when we get
                                        ; to / so that we only check it once

                                        ; While we've neither been at the top last time nor have we found
                                        ; the file.
    (while (not (or found top))
                                        ; If we're at / set top flag.
      (if (string= (expand-file-name dirname) "/")
	    (setq top t))

                                        ; Check for the file
      (if (file-exists-p (expand-file-name filename dirname))
	    (setq found t)
                                        ; If not, move up a directory
	    (setq dirname (expand-file-name ".." dirname))))
                                        ; return statement
    (if found dirname nil)))



(defun my-toggle-vterm ()
  (interactive)
  (if (eq (buffer-mode) 'vterm-mode)
    (cond
      ((bound-and-true-p popwin-mode) (popwin:close-popup-window))
      ((bound-and-true-p popper-mode) (popper-close-latest))
      (t (switch-to-buffer (other-buffer (current-buffer))))
      )
    (vterm)))

(defun popper-toggle-but-other-window()
  (interactive)
  (popper-toggle)
  (run-with-timer 0.05 nil
    (lambda ()
      (when popper-open-popup-alist
        (other-window -1))
      )))

(defun popper-cycle-but-other-window()
  (interactive)
  (popper-cycle 0)
  (run-with-timer 0.05 nil
    (lambda ()
      (when popper-open-popup-alist
        (other-window -1))
      )))


(defun start-zsh-term()
  (interactive)
  (vterm))


(defun toggle-continuation-fringe-indicator ()
  (interactive)
  (setq-default
    fringe-indicator-alist
    (if (assq 'continuation fringe-indicator-alist)
      (delq (assq 'continuation fringe-indicator-alist) fringe-indicator-alist)
      (cons '(continuation right-curly-arrow left-curly-arrow) fringe-indicator-alist))))

(defun my-toggle-truncate-lines-and-word-wrap()
  (interactive)
  (toggle-truncate-lines)
  (toggle-word-wrap))

(defun compileandrun()
  (interactive)
  (let* ((src (file-name-nondirectory (buffer-file-name)))
          (exe (file-name-sans-extension src)))
    (compile (concat "g++ " src " -std=c++20 " " -o " exe " && ./" exe))))


(defun save-buffer-without-hooks ()
  "Save current buffer without running any before/after save hooks."
  (interactive)
  (let ((before-save-hook nil)
         (after-save-hook nil))
    (save-buffer)))


(defun my-set-buffer-use-tabs ()
  (interactive)
  (make-local-variable 'indent-tabs-mode)
  (setq indent-tabs-mode t)
  (make-local-variable 'tab-width)
  (setq tab-width 4)
  )

(defun my-set-buffer-use-space ()
  (interactive)
  (make-local-variable 'indent-tabs-mode)
  (setq indent-tabs-mode nil)
  (make-local-variable 'tab-width)
  (setq tab-width 4)
  )

(defun my-untabify-buffer ()
  "将当前缓冲区中的所有 Tab 替换为 4 个空格。"
  (interactive)
  (my-set-buffer-use-space)
  (untabify (point-min) (point-max)))

(defun my-tabify-buffer ()
  "将当前缓冲区中的所有 Tab 替换为 4 个空格。"
  (interactive)
  (my-set-buffer-use-tabs)
  (tabify (point-min) (point-max)))


(defun my-hide-title-bar ()
  (interactive)
  (modify-frame-parameters nil '((undecorated . t)))
  (my-M-x)
  )

(defun my-show-title-bar ()
  (interactive)
  (modify-frame-parameters nil '((undecorated . nil)))
  (my-M-x)
  )

(defun my-set-proxy (&optional ip port)
  "Set HTTP/HTTPS proxy environment variables.
If called interactively, prompt for IP and port.
Default port is 9910 if not provided."
  (interactive)
  ;; 如果是交互式调用（M-x），提示用户输入
  (when (called-interactively-p 'interactive)
    (setq ip (read-string "Proxy IP (e.g. 127.0.0.1): " "127.0.0.1"))
    (setq port (read-number "Proxy Port (e.g. 9910): " 9910)))

  ;; 确保 port 是整数
  (unless (integerp port)
    (setq port (string-to-number (format "%s" port))))

  ;; 确保默认值
  (unless (> port 0)
    (setq port 9910))
  (unless (> (length ip) 0)
    (setq ip "127.0.0.1"))

  ;; 构造代理 URL
  (let ((proxy-url (format "http://%s:%d" ip port))
        (no-proxy-list "localhost,127.0.0.1,::1,192.168.0.0/16,172.16.0.0/12,10.0.0.0/8"))

    ;; 设置大小写两种形式（有些工具只认大写或小写）
    (dolist (var '("http_proxy" "https_proxy" "HTTP_PROXY" "HTTPS_PROXY"))
      (setenv var proxy-url))

    (dolist (var '("no_proxy" "NO_PROXY"))
      (setenv var no-proxy-list))

    (message "Proxy set to: %s (bypass: %s)" proxy-url no-proxy-list)))

(defun my-unset-proxy()
  (interactive)
  (setenv "http_proxy" nil)
  (setenv "https_proxy" nil)
  (setenv "HTTP_PROXY" nil)
  (setenv "HTTPS_PROXY" nil)
  )


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
  (next-line (/ (window-height (selected-window)) 2)))

(defun my-scroll-cursor-up ()
  (interactive)
  (previous-line (/ (window-height (selected-window)) 2)))

(defun run-command-in-directory (dir cmd &rest args)
  "Run a command in the specified directory.
If DIR is nil, use `default-directory'.
Return trimmed stdout if success, nil otherwise."
  (let* ((default-directory (or dir default-directory))
          (stdout-buffer (generate-new-buffer " *tmp-stdout*"))
          (exit-status (condition-case nil
                         (apply #'call-process cmd nil (list stdout-buffer nil) nil args)
                         (file-missing nil))))
    (unwind-protect
      (if (eq exit-status 0)
        (with-current-buffer stdout-buffer
          (string-trim (buffer-string)))
        nil)
      (kill-buffer stdout-buffer))))


(defun my-pp-region (beg end)
  "Use `pp' to format the selected Elisp code, then indent and untabify."
  (interactive "r")
  (let
    ((str (buffer-substring-no-properties beg end))
      insert-start
      insert-end)
    (save-excursion
      (delete-region beg end) (setq insert-start (point))
      (condition-case err
        (let ((sexp (read str))) (insert (pp-to-string sexp)))
        (error (insert str)
          (user-error "Failed to parse Elisp: %s"
            (error-message-string err))))
      (setq insert-end (point))
      (indent-region insert-start insert-end)
      (untabify insert-start insert-end))))


(defun cmake-download-cpm()
  (interactive)
  (let* ((cmake-dir (file-name-concat (cmake-project-find-root-directory) "cmake"))
          (cpm-file-path (file-name-concat cmake-dir "CPM.cmake")))
    (unless (file-exists-p cpm-file-path)
      (make-directory cmake-dir t)
      (url-copy-file
        "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.42.0/CPM.cmake"
        cpm-file-path t))
    (message "saved to %s" cpm-file-path)))



(provide 'my-utils)
