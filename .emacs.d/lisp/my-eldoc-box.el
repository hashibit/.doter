;; -*- lexical-binding: t -*-
;;; my-eldoc-box.el --- Eldoc-box popup helpers

;;; Code:

(defvar eldoc-box-position-function)
(defvar eldoc-box-offset)
(defvar my-term-popup-show-p)


(defun my-toggle-eldoc-box-help-at-point ()
  "Show or hide the documentation popup for the thing at point."
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
      (show-eldoc-popup-at-point))))
(defun my-eldoc-box-position-at-mouse (width _height)
  "Position eldoc-box childframe near the mouse cursor."
  (let* ((edges (window-pixel-edges))
         (right (nth 2 edges))
         (top (nth 1 edges))
         (offset-right (nth 1 eldoc-box-offset))
         (offset-top (nth 2 eldoc-box-offset))
         (extra-left-padding 80)) ; <--- 在这里设置你想要再往左移动的像素值
    (cons (- right width offset-right extra-left-padding) ; <--- 减去这个值就会往左移
          (+ top offset-top))))

(defun my-eldoc-box-show-type-definition ()
  "Toggle eldoc-box display of the full type definition at point.
Uses LSP textDocument/typeDefinition to navigate past re-exports directly
to the interface/class/type declaration, then extracts the full block."
  (interactive)
  (require 'eldoc-box)
  (if (and (bound-and-true-p eldoc-box--frame)
           (frame-live-p eldoc-box--frame)
           (frame-visible-p eldoc-box--frame))
      (eldoc-box-quit-frame)
    (unless (eglot-current-server)
      (user-error "No LSP server active"))
    (let* ((server     (eglot--current-server-or-lose))
           (pos-params (eglot--TextDocumentPositionParams))
           (locs       (or (ignore-errors
                             (eglot--request server :textDocument/typeDefinition
                                             pos-params :cancel-on-input t))
                           (ignore-errors
                             (eglot--request server :textDocument/definition
                                             pos-params :cancel-on-input t))))
           (loc        (cond ((vectorp locs) (and (> (length locs) 0) (aref locs 0)))
                             ((listp locs)   (car locs))
                             (t              locs))))
      (if (not loc)
          (message "No definition found for symbol at point")
        (let* ((uri      (plist-get loc :uri))
               (start    (plist-get (plist-get loc :range) :start))
               (line     (plist-get start :line))
               (file     (eglot-uri-to-path uri))
               (existing (find-buffer-visiting file))
               (buf      (or existing (find-file-noselect file t))))
          (unwind-protect
              (with-current-buffer buf
                (save-excursion
                  (goto-char (point-min))
                  (forward-line line)
                  (let* ((beg  (line-beginning-position))
                         (end  (save-excursion
                                 (when (re-search-forward "{" (+ beg 600) t)
                                   (backward-char)
                                   (when (and (boundp 'show-paren-data-function)
                                              show-paren-data-function)
                                     (let ((data (funcall show-paren-data-function)))
                                       (when (and data (nth 3 data) (not (nth 4 data)))
                                         (nth 3 data)))))))
                         (end  (or end (line-end-position 10))))
                    (font-lock-ensure beg end)
                    (let* ((text (buffer-substring beg end))
                           (eldoc-box-position-function #'my-eldoc-box-position-at-mouse))
                      (eldoc-box--display text)))))
            ;; 不是用户已打开的 buffer，用完即关
            (unless existing (kill-buffer buf))))))))


(provide 'my-eldoc-box)

;;; my-eldoc-box.el ends here
