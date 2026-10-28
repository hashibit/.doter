;; -*- lexical-binding: t -*-
;;; my-term-popup.el --- Popups in terminal Emacs

;;; Code:

(require 'cl-lib)
;; Emacs 31 起 tty 支持 child frame，corfu 自身即可，不再需要 corfu-terminal
(if (featurep 'tty-child-frames)
    (require 'corfu)
  (require 'corfu-terminal)
  (corfu-terminal-mode 1))


(require 'my-utils)
(declare-function corfu--popup-show "corfu")
(declare-function corfu--popup-hide "corfu")


(require 'popon)
(advice-add #'keyboard-quit :before #'popon-kill-all)


;; (setq my-term-popup-engine 'corfu-terminal)
(defvar my-term-popup-engine 'popon)

(defvar my-term-popup-show-p nil)

(defvar my-term-popup-close-commands
  '(next-line previous-line forward-char backward-char
              scroll-up-command scroll-down-command
              gcm-scroll-down gcm-scroll-up
              scroll-half-page-up scroll-half-page-down
              xref-go-back xref-go-forward keyboard-quit)
  "Commands that close the popup.")

(defun my-term-popup--post-command ()
  (when (memq this-command my-term-popup-close-commands)
    (my-term-popup-close)))

(defun my-term-popup--opened ()
  (setq my-term-popup-show-p t)
  (add-hook 'post-command-hook #'my-term-popup--post-command))

(defun my-term-popup-close (&rest _)
  "Close the terminal popup."
  (interactive)
  (remove-hook 'post-command-hook #'my-term-popup--post-command)
  (when my-term-popup-show-p
    (ignore-errors (corfu--popup-hide))
    (if (window-parameter (get-buffer-window) 'popon-list)
        (popon-kill-all))
    (setq my-term-popup-show-p nil)))




(defun show-eldoc-popup-at-point ()
  "Show the eldoc documentation in a popup at point."
  (interactive)
  (when-let* ((doc-buffer (bound-and-true-p eldoc--doc-buffer))
              ((buffer-live-p doc-buffer)))
    (let* ((str (with-current-buffer doc-buffer
                  (buffer-string)))
           (lines (string-split str "\n")))
      (my-show-popup lines))))



(defun my-show-popup(&optional lines)
  "Show LINES in a popup at point."
  (interactive)
  (let* (
         (lines (or lines
                    (split-string (my-util-read-fmt-content "~/.emacs.d/lisp/my-utils.el") "\n") ;; for test
                    ))
         (display-width (- (window-width) 8))

         (content-width (- (window-body-width) 10)) ;; don't count the line-number column , and the border chars
         (border-line (make-string (1+ content-width) ?─))
         (lines (nconc (list border-line) lines (list border-line)))
         ;; (_ (message "lines number %d: \n%s\n"  (length lines) lines))
         (lines-size (length lines))
         (idx 0)
         (lines
          (cl-loop for line in lines
                   do (setq idx (1+ idx))
                   collect (cond
                            ((= 1 idx) (concat "┌" line))
                            ((= lines-size idx) (concat "└" line))
                            ((string= line "---") (concat "│" border-line))
                            (t (concat "│ " line))))))

    (if (eq my-term-popup-engine 'popon)
        ;; implemented using popon
        (show-popup-with-popon lines display-width)
      ;; implemented using corfu-terminal, I think it's more stable
      (show-popup-with-corfu-terminal lines display-width))
    (my-term-popup--opened)))

(defun show-popup-with-popon(lines _display-width)
  (popon-create
   (string-join lines "\n")
   (cons 0
         (+ (cdr (popon-x-y-at-pos (point))) 1))
   (get-buffer-window)
   (current-buffer)))

(defun show-popup-with-corfu-terminal(lines display-width)
  (progn
    (setq lines (cl-loop for line in lines
                         collect (cond
                                  ((> (length line) display-width)
                                   (substring-no-properties line 0 display-width))
                                  ((< (length line) display-width)
                                   (concat line (make-string (- display-width (length line)) ?\s)))
                                  (t line))))
    (corfu--popup-show
     (posn-at-point)
     (save-excursion (goto-char (point)) (current-column))
     display-width
     lines)))

(defun my-show-popup-test ()
  "Show a test popup."
  (interactive)
  (my-show-popup (list "hello this is a" "new line" "hhehe")))

(keymap-global-set "C-c C-i" #'my-show-popup)
(keymap-global-set "C-c C-j" #'my-show-popup-test)



(provide 'my-term-popup)

;;; my-term-popup.el ends here
