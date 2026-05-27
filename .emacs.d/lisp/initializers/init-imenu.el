;;; -*- lexical-binding: t -*-

(setq imenu-list-size 0.20)
(setq imenu-list-auto-update nil)

(defun my-imenu-list-smart-toggle-refresh ()
  (interactive)
  (when (and (bound-and-true-p imenu-list-buffer-name)
             (get-buffer-window imenu-list-buffer-name t))
    (imenu-list-quit-window))
  (imenu-list-minor-mode 1)
  (select-window (get-buffer-window (imenu-list-get-buffer-create))))

(use-package imenu-list
  :defer t
  :bind ((:map imenu-list-major-mode-map
               ("H" . (lambda () (interactive) (enlarge-window-horizontally (/ (frame-width) 3))))
               ("M" . imenu-list-resize-window)
               ("L" . (lambda () (interactive) (shrink-window-horizontally (/ (frame-width) 3))))
               ("m" . my-imenu-list-smart-toggle-refresh))))

;;; Struct method filter sidebar

(defface my-imenu-group-face
  '((t :inherit font-lock-type-face :weight bold))
  "Face for impl block headers in struct method sidebar.")

(defface my-imenu-file-face
  '((t :foreground "#57D8D4" :weight bold))
  "Face for file name headers in struct method sidebar.")

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
                (let* ((start (save-excursion (forward-line (- context-lines)) (point)))
                       (end   (save-excursion (forward-line context-lines) (point))))
                  (font-lock-ensure start end)
                  (list (buffer-substring start end)
                        (- (line-number-at-pos pos) (line-number-at-pos start)))))))
           (text (car content))
           (highlight-line (cadr content))
           (peek-buf (get-buffer-create " *imenu-peek*")))
      (with-current-buffer peek-buf
        (read-only-mode -1)
        (erase-buffer)
        (setq-local truncate-lines t)
        (insert text)
        (goto-char (point-min))
        (forward-line highlight-line)
        (add-text-properties (line-beginning-position) (line-end-position) '(face highlight))
        (read-only-mode 1))
      (let ((pf (posframe-show peek-buf
                               :poshandler #'my-imenu-peek--poshandler
                               :width 80
                               :height (1+ (* 2 context-lines))
                               :border-width 1
                               :border-color (face-foreground 'font-lock-comment-face nil t)
                               :background-color (face-background 'default nil t))))
        (when (framep pf)
          (with-selected-window (frame-root-window pf)
            (setq truncate-lines t))))
      (setq my-imenu-peek--visible t)
      (setq my-imenu-peek--last-line (line-number-at-pos))
      (add-hook 'post-command-hook #'my-imenu-peek--maybe-hide nil t))))

(defun my-imenu-peek ()
  "Toggle posframe preview of the code around the item under point."
  (interactive)
  (if my-imenu-peek--visible (my-imenu-peek--hide) (my-imenu-peek--show)))

(defun my-imenu--finalize-sidebar (buf)
  "Set up keybindings in BUF and display it as a right-side sidebar."
  (with-current-buffer buf
    (imenu-list-major-mode)
    (goto-char (point-min))
    (local-set-key (kbd "RET") #'my-imenu-jump)
    (local-set-key (kbd "SPC") #'my-imenu-peek)
    (local-set-key (kbd "q") (lambda ()
                               (interactive)
                               (when my-imenu-peek--visible (my-imenu-peek--hide))
                               (quit-window))))
  (display-buffer buf '(display-buffer-in-side-window (side . right) (window-width . 35))))

(defvar my-imenu-method-group-patterns
  '((rust-mode          . "\\`impl\\b")
    (rust-ts-mode       . "\\`impl\\b")
    (python-mode        . "\\`class\\b")
    (python-ts-mode     . "\\`class\\b")
    (go-mode            . "\\`\\(type\\|func\\)\\b")
    (go-ts-mode         . "\\`\\(type\\|func\\)\\b")
    (c++-mode           . "\\`\\(class\\|struct\\|namespace\\)\\b")
    (c++-ts-mode        . "\\`\\(class\\|struct\\|namespace\\)\\b")
    (java-mode          . "\\`\\(class\\|interface\\|enum\\)\\b")
    (java-ts-mode       . "\\`\\(class\\|interface\\|enum\\)\\b"))
  "Alist mapping major-mode to a regexp matching method-bearing group names.")

(defun my-imenu-method-group-p (group-name src-buffer)
  "Return non-nil if GROUP-NAME represents a method-bearing group in SRC-BUFFER."
  (when-let ((pattern (alist-get (buffer-local-value 'major-mode src-buffer)
                                 my-imenu-method-group-patterns)))
    (string-match-p pattern group-name)))

(defun my-imenu-filter-struct (struct-name)
  "Show a sidebar with all impl blocks matching STRUCT-NAME.
If region is active, use the selected text as input."
  (interactive
   (list (if (use-region-p)
             (prog1 (buffer-substring-no-properties (region-beginning) (region-end))
               (deactivate-mark))
           (read-string "Struct name: "))))
  (let* ((items (imenu--make-index-alist t))
         (filtered (seq-filter (lambda (item)
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
            (add-text-properties group-start (1- (point)) '(face my-imenu-group-face)))
          (let ((is-method-group (my-imenu-method-group-p (car group) src)))
            (dolist (method (cdr group))
              (let ((start (point))
                    (item-face (if is-method-group 'my-imenu-method-face 'my-imenu-field-face)))
                (insert "  " (car method) "\n")
                (add-text-properties start (1- (point))
                                     `(face ,item-face
                                       mouse-face my-imenu-method-hover-face
                                       my-imenu-pos (,src ,(cdr method)))))))))
      (my-imenu--finalize-sidebar buf))))

;;; Eglot cross-file struct method finder

(defun my-imenu--uri-to-path (uri)
  "Convert LSP file URI to local path."
  (if (fboundp 'eglot-uri-to-path)
      (eglot-uri-to-path uri)
    (expand-file-name (url-unhex-string
                       (replace-regexp-in-string "\\`file://" "" uri)))))

(defun my-imenu--render-from-files (struct-name paths src-buf)
  "Run imenu on each path in PATHS, collect groups matching STRUCT-NAME, render sidebar."
  (let ((buf (get-buffer-create "*Ilist-struct-methods*"))
        (root (or (when (project-current) (project-root (project-current))) ""))
        all-groups)
    (dolist (path paths)
      (when (file-exists-p path)
        (let* ((file-buf (find-file-noselect path))
               (items (with-current-buffer file-buf (imenu--make-index-alist t)))
               (matches (seq-filter (lambda (item)
                                      (and (imenu--subalist-p item)
                                           (string-match-p (regexp-quote struct-name) (car item))))
                                    items)))
          (when matches (push (cons path matches) all-groups)))))
    (if (null all-groups)
        (progn
          (message "No impl blocks found for %s, falling back to current file" struct-name)
          (with-current-buffer src-buf (my-imenu-filter-struct struct-name)))
      (with-current-buffer buf
        (read-only-mode -1)
        (erase-buffer)
        (pcase-dolist (`(,path . ,groups) (nreverse all-groups))
          (let* ((file-buf (find-file-noselect path))
                 (short (file-relative-name path root))
                 (hdr-start (point)))
            (insert "── " short " ──\n")
            (add-text-properties hdr-start (1- (point)) '(face my-imenu-file-face))
            (dolist (group groups)
              (let ((group-start (point)))
                (insert (car group) "\n")
                (add-text-properties group-start (1- (point)) '(face my-imenu-group-face)))
              (let ((is-method (my-imenu-method-group-p (car group) file-buf)))
                (dolist (method (cdr group))
                  (let ((item-start (point))
                        (item-face (if is-method 'my-imenu-method-face 'my-imenu-field-face)))
                    (insert "  " (car method) "\n")
                    (add-text-properties item-start (1- (point))
                                         `(face ,item-face
                                           mouse-face my-imenu-method-hover-face
                                           my-imenu-pos (,file-buf ,(cdr method)))))))))))
      (my-imenu--finalize-sidebar buf))))

(defun my-imenu-filter-struct-eglot (struct-name)
  "Show all methods of STRUCT-NAME across the project.
Uses eglot workspace/symbol to find the definition, then textDocument/references
to get all files, then imenu on those files.
Falls back to `my-imenu-filter-struct' if eglot is unavailable."
  (interactive
   (list (if (use-region-p)
             (prog1 (buffer-substring-no-properties (region-beginning) (region-end))
               (deactivate-mark))
           (read-string "Struct name: "))))
  (let ((server (eglot-current-server))
        (src-buf (current-buffer)))
    (cl-flet ((fallback () (with-current-buffer src-buf (my-imenu-filter-struct struct-name))))
      (if (not server)
          (progn (message "eglot not connected, using imenu fallback") (fallback))
        (jsonrpc-async-request
         server
         :workspace/symbol
         `(:query ,struct-name)
         :timeout 5
         :success-fn
         (lambda (symbols)
           (let* ((sym-list (append symbols nil))
                  (struct-kinds '(5 10 11 23)) ; Class Interface Enum Struct
                  (def (seq-find (lambda (s)
                                   (and (string= (plist-get s :name) struct-name)
                                        (memq (plist-get s :kind) struct-kinds)))
                                 sym-list)))
             (if (not def)
                 (progn (message "Cannot find definition of %s, falling back" struct-name) (fallback))
               (let* ((loc   (plist-get def :location))
                      (uri   (plist-get loc :uri))
                      (start (plist-get (plist-get loc :range) :start))
                      (line  (plist-get start :line))
                      (char  (plist-get start :character)))
                 (jsonrpc-async-request
                  server
                  :textDocument/references
                  `(:textDocument (:uri ,uri)
                    :position (:line ,line :character ,char)
                    :context (:includeDeclaration t))
                  :timeout 10
                  :success-fn
                  (lambda (refs)
                    (let ((paths (delete-dups
                                  (mapcar (lambda (r) (my-imenu--uri-to-path (plist-get r :uri)))
                                          (append refs nil)))))
                      (message "[imenu-eglot] %s: found %d reference(s) in %d file(s): %s"
                               struct-name (length (append refs nil)) (length paths)
                               (mapconcat #'file-name-nondirectory paths ", "))
                      (my-imenu--render-from-files struct-name paths src-buf)))
                  :error-fn   (lambda (err) (message "references failed: %s, falling back" err) (fallback))
                  :timeout-fn (lambda () (message "references timed out, falling back") (fallback)))))))
         :error-fn   (lambda (err) (message "workspace/symbol failed: %s, falling back" err) (fallback))
         :timeout-fn (lambda () (message "workspace/symbol timed out, falling back") (fallback)))))))

;;; JS/TS imenu: filter locals + annotate exports

(defvar my-imenu-js-export-marker "⬡ "
  "String prepended to exported JS/TS symbols in imenu.")

(defconst my-imenu-js--scope-boundaries
  '("program" "class_body" "statement_block" "object" "formal_parameters")
  "Treesit node types treated as scope boundaries for imenu filtering.
`program' and `class_body' are significant (items kept).
`statement_block', `object', `formal_parameters' are not (items dropped).")

(defun my-imenu-js--significant-p (pos)
  "Return non-nil if POS is at a top-level or class-level scope.
Walks up the treesit tree to the nearest scope boundary.
Returns t only when the boundary is `program' or `class_body'."
  (and (treesit-available-p)
       (treesit-parser-list)
       (condition-case nil
           (let ((node (treesit-node-at (if (markerp pos) (marker-position pos) pos))))
             (while (and node (not (member (treesit-node-type node)
                                          my-imenu-js--scope-boundaries)))
               (setq node (treesit-node-parent node)))
             (member (treesit-node-type node) '("program" "class_body")))
         (error nil))))

(defun my-imenu-js--remove-insignificant (index)
  "Filter INDEX: drop non-significant leaves; collapse childless groups to leaves."
  (mapcan
   (lambda (item)
     (cond
      ((not (imenu--subalist-p item))
       (when (my-imenu-js--significant-p (cdr item)) (list item)))
      (t
       (let* ((children  (cdr item))
              (self-entry (assoc " " children))
              (self-pos   (cdr self-entry))
              (rest       (seq-remove (lambda (c) (equal (car c) " ")) children))
              (filtered   (my-imenu-js--remove-insignificant rest)))
         (cond
          (filtered
           ;; Real children remain: keep as group, restore " " for navigation.
           (list (cons (car item) (if self-entry
                                      (cons self-entry filtered)
                                    filtered))))
          (self-pos
           ;; No real children but has position: collapse to a leaf entry.
           (list (cons (car item) self-pos)))
          (t nil))))))
   index))

(defun my-imenu-js--exported-p (pos)
  "Return non-nil if the line at POS begins with an export keyword."
  (save-excursion
    (goto-char (if (markerp pos) (marker-position pos) pos))
    (beginning-of-line)
    (looking-at "[ \t]*export\\b")))

(defun my-imenu-js--annotate (index)
  "Recursively prefix exported entries in INDEX with `my-imenu-js-export-marker'.
For groups, the export check uses their \" \" self-reference child (which is
then dropped from output to avoid the blank Go-to line in imenu-list)."
  (mapcan
   (lambda (item)
     (cond
      ((imenu--subalist-p item)
       (let* ((children (cdr item))
              (self-pos (cdr (assoc " " children)))
              (exported (and self-pos (my-imenu-js--exported-p self-pos)))
              (name (if exported (concat my-imenu-js-export-marker (car item)) (car item))))
         (list (cons name (my-imenu-js--annotate children)))))
      ;; Rename " " self-reference to a visible symbol so it's navigable.
      ((equal (car item) " ") (list (cons "·" (cdr item))))
      ((and (consp item) (cdr item) (my-imenu-js--exported-p (cdr item)))
       (list (cons (concat my-imenu-js-export-marker (car item)) (cdr item))))
      (t (list item))))
   index))

(defun my-imenu-js-setup ()
  "Wrap imenu to filter local-scope entries and annotate exports.
Uses treesit-simple-imenu as base directly — eglot's :before-until advice
on that function is preserved, so this works with or without eglot.
Idempotent: safe to call multiple times."
  (interactive)
  (setq-local imenu-create-index-function
              (lambda ()
                (thread-first (treesit-simple-imenu)
                              my-imenu-js--remove-insignificant
                              my-imenu-js--annotate))))

(dolist (hook '(js-ts-mode-hook jtsx-typescript-mode-hook jtsx-tsx-mode-hook jtsx-jsx-mode-hook))
  (add-hook hook #'my-imenu-js-setup))

(provide 'init-imenu)
