

;; imenu size sidebar width, 0.20 of screen
;; NOTE: <SPC>-i to toggle imenu sidebar
(setq imenu-list-size 0.20)
(setq imenu-list-auto-update nil)

(defun my-enlarge-imenu-width ()
  (interactive)
  (enlarge-window-horizontally (/ (frame-width) 3)))

(defun my-shrink-imenu-width ()
  (interactive)
  (shrink-window-horizontally (/ (frame-width) 3)))

(defun my-fit-imenu-width ()
  (interactive)
  (imenu-list-resize-window))

(defun my-imenu-list-check-window-is-open ()
  (interactive)
  (and
    (bound-and-true-p imenu-list-buffer-name)
    (get-buffer-window imenu-list-buffer-name t)
    t))


(defun my-imenu-list-smart-toggle-refresh ()
  (interactive)
  (when (my-imenu-list-check-window-is-open)
    (imenu-list-quit-window))
  (imenu-list-minor-mode 1)
  (select-window (get-buffer-window (imenu-list-get-buffer-create))))

(use-package imenu-list
  :defer t
  :bind ((:map
           imenu-list-major-mode-map
           ("H" . my-enlarge-imenu-width)
           ("M" . my-fit-imenu-width)
           ("L" . my-shrink-imenu-width)
           ("m" . my-imenu-list-smart-toggle-refresh))))

;;; Struct method filter sidebar

(defface my-imenu-group-face
  '((t :inherit font-lock-type-face :weight bold))
  "Face for impl block headers in struct method sidebar.")

(defface my-imenu-method-face
  '((t :inherit font-lock-function-name-face))
  "Face for method names in struct method sidebar.")

(defface my-imenu-field-face
  '((t :inherit font-lock-variable-name-face))
  "Face for field names in struct method sidebar.")

(defface my-imenu-method-hover-face
  '((t :inherit highlight))
  "Face for hovered method in struct method sidebar.")

(defun my-imenu-jump ()
  "Jump to the item under point in the struct methods buffer."
  (interactive)
  (when my-imenu-peek--visible
    (my-imenu-peek--hide))
  (when-let ((data (get-text-property (point) 'my-imenu-pos)))
    (pop-to-buffer (car data))
    (goto-char (cadr data))))

(defvar my-imenu-peek--visible nil
  "Whether the imenu peek posframe is currently visible.")

(defun my-imenu-peek--poshandler (info)
  "Position posframe so its right edge aligns with the sidebar's left edge."
  (cons (- (plist-get info :parent-window-left)
            (plist-get info :posframe-width))
        (plist-get info :parent-window-top)))

(defun my-imenu-peek--hide ()
  "Hide the peek posframe and clean up the post-command hook."
  (posframe-hide " *imenu-peek*")
  (setq my-imenu-peek--visible nil)
  (remove-hook 'post-command-hook #'my-imenu-peek--maybe-hide t))

(defvar my-imenu-peek--last-line nil
  "Line number when peek was last shown.")

(defun my-imenu-peek--maybe-hide ()
  "Auto-update peek posframe when cursor moves to a new line."
  (unless (eq this-command 'my-imenu-peek)
    (let ((current-line (line-number-at-pos)))
      (if (eq current-line my-imenu-peek--last-line)
          (my-imenu-peek--hide)
        (my-imenu-peek--show)))))

(defun my-imenu-peek--show ()
  "Show posframe preview for the item under point."
  (when-let ((data (get-text-property (point) 'my-imenu-pos)))
    (let* ((src (car data))
           (pos (cadr data))
           (context-lines 10)
           (content
            (with-current-buffer src
              (save-excursion
                (goto-char pos)
                (let* ((start (save-excursion
                                (forward-line (- context-lines))
                                (point)))
                       (end (save-excursion
                              (forward-line context-lines)
                              (point))))
                  (font-lock-ensure start end)
                  (let* ((text (buffer-substring start end))
                         (target-line (line-number-at-pos pos))
                         (start-line (line-number-at-pos start)))
                    (list text (- target-line start-line)))))))
           (text (car content))
           (highlight-line (cadr content))
           (peek-buf (get-buffer-create " *imenu-peek*")))
      (with-current-buffer peek-buf
        (read-only-mode -1)
        (erase-buffer)
        (insert text)
        (goto-char (point-min))
        (forward-line highlight-line)
        (add-text-properties (line-beginning-position) (line-end-position)
                             '(face highlight))
        (read-only-mode 1))
      (posframe-show peek-buf
                     :poshandler #'my-imenu-peek--poshandler
                     :width 80
                     :height (1+ (* 2 context-lines))
                     :border-width 1
                     :border-color (face-foreground 'font-lock-comment-face nil t)
                     :background-color (face-background 'default nil t))
      (setq my-imenu-peek--visible t)
      (setq my-imenu-peek--last-line (line-number-at-pos))
      (add-hook 'post-command-hook #'my-imenu-peek--maybe-hide nil t))))

(defun my-imenu-peek ()
  "Toggle posframe preview of the code around the item under point."
  (interactive)
  (if my-imenu-peek--visible
      (my-imenu-peek--hide)
    (my-imenu-peek--show)))

(defun my-imenu-filter-struct (struct-name)
  "Show a sidebar with all impl blocks matching STRUCT-NAME.
If region is active, use the selected text as input."
  (interactive
   (list (if (use-region-p)
             (prog1 (buffer-substring-no-properties (region-beginning) (region-end))
               (deactivate-mark))
           (read-string "Struct name: "))))
  (let* ((items (imenu--make-index-alist t))
         (filtered (seq-filter
                    (lambda (item)
                      (and (imenu--subalist-p item)
                           (string-match-p struct-name (car item))))
                    items))
         (buf (get-buffer-create "*Ilist-struct-methods*"))
         (src (current-buffer)))
    (if (null filtered)
        (message "No impl blocks found matching: %s" struct-name)
      (with-current-buffer buf
        (read-only-mode -1)
        (erase-buffer)
        (dolist (group filtered)
          (let ((group-start (point)))
            (insert (car group) "\n")
            (add-text-properties group-start (1- (point))
                                 '(face my-imenu-group-face)))
          (let ((is-impl (string-match-p "\\`impl\\b" (car group))))
            (dolist (method (cdr group))
              (let ((start (point))
                    (item-face (if is-impl 'my-imenu-method-face 'my-imenu-field-face)))
                (insert "  " (car method) "\n")
                (add-text-properties start (1- (point))
                                     `(face ,item-face
                                       mouse-face my-imenu-method-hover-face
                                       my-imenu-pos (,src ,(cdr method))))))))
        (imenu-list-major-mode)
        (goto-char (point-min))
        (local-set-key (kbd "RET") #'my-imenu-jump)
        (local-set-key (kbd "SPC") #'my-imenu-peek)
        (local-set-key (kbd "q") #'quit-window))
      (display-buffer buf '(display-buffer-in-side-window
                            (side . right)
                            (window-width . 35))))))

(provide 'init-imenu)
