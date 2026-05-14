

(defun my-recenter-scroll-to-top ()
  (interactive)
  (recenter-top-bottom 1)
  (setq recenter-last-op nil))


;; quit xref buffer after enter
(with-eval-after-load 'xref
  (define-key xref--xref-buffer-mode-map (kbd "o") #'(lambda ()
                                                       (interactive)
                                                       (xref-goto-xref t)))



  ;; jump back with window scroll position
  (defvar my-xref-window-starts (make-hash-table :test 'equal))

  (defun my-xref--save-window-start (&optional _m)
    "Save window-start keyed by (buffer . position) before push."
    (let ((ws (window-start)))
      ;; (message "-------- save ws: %s" ws)
      (puthash (cons (current-buffer) (point))
        (window-start)
        my-xref-window-starts)))

  (defun my-xref--restore-window-start (&rest _)
    "Restore window-start after xref-go-back."
    (let ((ws (gethash (cons (current-buffer) (point))
                my-xref-window-starts)))
      ;; (message "------------debug ws %s" ws)
      (when ws
        (set-window-start nil ws)
        (remhash (cons (current-buffer) (point))
          my-xref-window-starts))))


  (advice-add 'xref-find-definitions :before #'my-xref--save-window-start)
  (advice-add 'xref-find-references :before #'my-xref--save-window-start)

  (advice-add 'xref-go-back :after #'my-xref--restore-window-start)
  (advice-add 'xref-go-forward :after #'my-xref--restore-window-start)


  ;; directly open it when there is only one candidate.
  ;; (setq xref-show-xrefs-function #'xref-show-definitions-buffer)
  ;; (setq xref-show-xrefs-function #'xref-show-definitions-buffer-at-bottom)

  ;; (add-to-list 'xref-after-return-hook 'my-recenter-scroll-to-top)
  ;; (setq xref-after-jump-hook (delete 'recenter xref-after-jump-hook))
  ;; (add-to-list 'xref-after-jump-hook 'my-recenter-scroll-to-top)
  )

(defun ivy-xref-call-or-done ()
  (interactive)
  (let (orig-point orig-buffer new-point new-buffer)
    (with-ivy-window
      (setq
        orig-point (point)
        orig-buffer (current-buffer)))

    (ivy-call)

    (with-ivy-window
      (setq
        new-point (point)
        new-buffer (current-buffer)))

    (when (and (eq new-point orig-point) (eq new-buffer orig-buffer))
      (ivy-done))))

;;; xref peek via posframe ---------------------------------------------------

(defvar my-xref-peek--enabled nil)
(defconst my-xref-peek--buffer " *xref-peek*")
(defvar my-xref-peek--context 24 "Lines of context shown in peek.")
(defvar my-xref-peek--file-cache (make-hash-table :test 'equal)
  "Cache of file path → fontified buffer, alive for one xref session.")

(defun my-xref-peek--get-file-buffer (file)
  "Return a cached fontified buffer for FILE, creating it if needed."
  (or (gethash file my-xref-peek--file-cache)
      (let ((buf (generate-new-buffer (concat " *xref-peek-src:" (file-name-nondirectory file) "*"))))
        (with-current-buffer buf
          (insert-file-contents file)
          (let ((mode (assoc-default file auto-mode-alist 'string-match)))
            (when (and mode (functionp mode))
              (delay-mode-hooks (funcall mode))))
          (font-lock-ensure))
        (puthash file buf my-xref-peek--file-cache)
        buf)))

(defun my-xref-peek--show (file line)
  "Render peek posframe for FILE at LINE."
  (let* ((src-buf (my-xref-peek--get-file-buffer file))
         (half (/ my-xref-peek--context 2))
         (extract-ctx 200)
         (beg-line (max 1 (- line extract-ctx)))
         (win-start-line (max 1 (- line half)))
         (half-width (/ (frame-width) 2))
         (peek-width (if (< half-width 120)
                         (/ (* (frame-width) 3) 4)
                       half-width))
         (text (with-current-buffer src-buf
                 (goto-char (point-min))
                 (forward-line (1- beg-line))
                 (let ((beg (point)))
                   (forward-line (* extract-ctx 2))
                   (buffer-substring beg (min (point) (point-max))))))
         (display-buf (get-buffer-create my-xref-peek--buffer)))
    (with-current-buffer display-buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (remove-overlays)
        (insert text)
        ;; highlight target line
        (goto-char (point-min))
        (forward-line (- line beg-line))
        (overlay-put
         (make-overlay (line-beginning-position) (1+ (line-end-position)))
         'face '(:background "#2a3f5a"))
        ;; position point at window-start line
        (goto-char (point-min))
        (forward-line (- win-start-line beg-line))))
    (posframe-show display-buf
      :poshandler (lambda (info)
                    (cons (- (plist-get info :parent-frame-width)
                             (plist-get info :posframe-width)
                             10)
                          0))
      :width peek-width
      :height (+ my-xref-peek--context 2)
      :border-width 1
      :border-color "#4a5a7a"
      :background-color "#181818"
      :internal-border-width 3
      :accept-focus nil)
    (let ((win (get-buffer-window display-buf t)))
      (when win
        (with-current-buffer display-buf
          (set-window-start win (point)))))))

(defun my-xref-peek--update ()
  "Called by ivy-update-fns-alist on candidate change."
  (when my-xref-peek--enabled
    (let* ((current (ivy-state-current ivy-last))
            (candidate (assoc current (ivy-state-collection ivy-last))))
      (when (consp candidate)
        (let* ((loc (cdr candidate))
                (file (xref-location-group loc))
                (line (xref-file-location-line loc)))
          (when (and file line (file-readable-p file))
            (my-xref-peek--show file line)))))))

(defun my-xref-peek--hide ()
  (setq my-xref-peek--enabled nil)
  (posframe-hide my-xref-peek--buffer)
  (maphash (lambda (_file buf) (when (buffer-live-p buf) (kill-buffer buf)))
           my-xref-peek--file-cache)
  (clrhash my-xref-peek--file-cache))

(defun my-xref-peek-toggle ()
  "Toggle xref peek preview. Bound to C-l in ivy-xref."
  (interactive)
  (setq my-xref-peek--enabled (not my-xref-peek--enabled))
  (if my-xref-peek--enabled
      (my-xref-peek--update)
    (posframe-hide my-xref-peek--buffer)))


(defun my-xref-peek-hide ()
  "Hide xref peek posframe."
  (interactive)
  (setq my-xref-peek--enabled nil)
  (posframe-hide my-xref-peek--buffer))


(add-hook 'minibuffer-exit-hook #'my-xref-peek--hide)

(with-eval-after-load 'ivy
  (add-to-list 'ivy-update-fns-alist '(ivy-xref-show-xrefs . my-xref-peek--update))
  (add-to-list 'ivy-update-fns-alist '(ivy-xref-show-defs  . my-xref-peek--update)))


(defun my-xref-show-xrefs-function (fetcher alist)
  "Jump to the first xref if there's only one result."
  (let* ((xrefs (funcall fetcher)))
    (if (= (length xrefs) 1)
      (let* ((item (car xrefs))
              (location (xref-item-location item))
              (target-buffer (find-file-noselect (xref-location-group location))))
        (switch-to-buffer target-buffer)
        (goto-char (point-min))
        (forward-line (1- (xref-file-location-line location)))
        (forward-char (xref-file-location-column location)))
      (ivy-xref-show-xrefs fetcher alist))))


(use-package ivy-xref
  :ensure t
  :after (ivy xref)
  :init
  (setq xref-show-definitions-function #'ivy-xref-show-defs)
  (setq xref-show-xrefs-function #'my-xref-show-xrefs-function)
  :bind
  (:map
    ivy-minibuffer-map
    ("M-l" . ivy-call-and-recenter))
  :config
  (define-key ivy-minibuffer-map (kbd "C-l") #'my-xref-peek-toggle))


(provide 'init-xref)
