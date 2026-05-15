

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
  (when-let ((data (get-text-property (point) 'my-imenu-pos)))
    (pop-to-buffer (car data))
    (goto-char (cadr data))))

(defun my-imenu-filter-struct (struct-name)
  "Show a sidebar with all impl blocks matching STRUCT-NAME.
If region is active, use the selected text as input."
  (interactive
   (list (if (use-region-p)
             (buffer-substring-no-properties (region-beginning) (region-end))
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
        (local-set-key (kbd "q") #'quit-window))
      (display-buffer buf '(display-buffer-in-side-window
                            (side . right)
                            (window-width . 35))))))

(provide 'init-imenu)
