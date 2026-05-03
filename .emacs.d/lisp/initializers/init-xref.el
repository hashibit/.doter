

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
    ("C-l" . ivy-xref-call-or-done)
    ("M-l" . ivy-call-and-recenter)))


(provide 'init-xref)
