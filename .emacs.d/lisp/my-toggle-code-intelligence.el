;; -*- lexical-binding: t -*-
;;; my-toggle-code-intelligence.el --- Turn LSP highlight and code intelligence on and off

;;; Code:

(require 'init-flymake)

(defvar-local my-code-intelligence t
  "enable by default")

(defvar my-code-intelligence--disabled-buffers nil
  "Buffers in which code intelligence is currently disabled.")

(defvar my-electric-pair-saved nil
  "Global `electric-pair-mode' state saved before disabling code intelligence.")

(defvar-local my-symbol-overlay-saved nil
  "Non-nil if `symbol-overlay-mode' was on before it was disabled.")

(defvar-local my-eglot-highlight-disabled nil
  "Non-nil if the eglot highlight face is remapped off in this buffer.")

(defvar my-eglot-highlight-symbol-face-saved 'my-highlight-font-words-face
  "face inherited by eglot-highlight-symbol-face")

(defvar my-disable-timeout nil)

(defvar eglot-ignored-server-capabilities)
(defvar symbol-overlay-mode)
(declare-function symbol-overlay-mode "symbol-overlay")
(declare-function remove-all-highlight "my-highlight-current-line")


(with-eval-after-load 'eglot
  (set-face-attribute 'eglot-highlight-symbol-face nil
                      :inherit my-eglot-highlight-symbol-face-saved))


(defvar-local my-run-later--timers nil
  "Alist of (FN . TIMER) scheduled by `my-run-later-in-buffer'.")

(defun my-cancel-later (fn)
  "Cancel the pending call of FN in the current buffer, if any."
  (when-let* ((cell (assq fn my-run-later--timers)))
    (cancel-timer (cdr cell))
    (setq my-run-later--timers (delq cell my-run-later--timers))))

(defun my-run-later-in-buffer (fn)
  "Run FN after `my-disable-timeout' in the current buffer."
  (my-cancel-later fn)
  (let* ((buf (current-buffer))
         (timer (run-with-timer my-disable-timeout nil
                                (lambda ()
                                  (when (buffer-live-p buf)
                                    (with-current-buffer buf
                                      (setq my-run-later--timers (assq-delete-all fn my-run-later--timers))
                                      (ignore-errors (funcall fn))))))))
    (push (cons fn timer) my-run-later--timers)))


(defun my-disable-eglot-highlight--now ()
  (when (boundp 'eglot-ignored-server-capabilities)
    (add-to-list 'eglot-ignored-server-capabilities :documentHighlightProvider))
  (unless my-eglot-highlight-disabled
    ;; buffer-local: 去掉 eglot-highlight-symbol-face 的所有属性
    (face-remap-set-base 'eglot-highlight-symbol-face '(:inherit nil))
    (setq my-eglot-highlight-disabled t)))

(defun my-disable-eglot-highlight (&rest _)
  "Turn off eglot symbol highlight, after a short delay."
  (interactive)
  (my-run-later-in-buffer #'my-disable-eglot-highlight--now))

(defun my-enable-eglot-highlight (&rest _)
  "Turn on eglot symbol highlight again."
  (interactive)
  (my-cancel-later #'my-disable-eglot-highlight--now)
  (ignore-errors
    (when (boundp 'eglot-ignored-server-capabilities)
      (setq eglot-ignored-server-capabilities
            (delq :documentHighlightProvider eglot-ignored-server-capabilities)))
    (when my-eglot-highlight-disabled
      (face-remap-reset-base 'eglot-highlight-symbol-face)
      (setq my-eglot-highlight-disabled nil))))



(defun my-enable-paren-highlight ()
  "Turn on the matching-paren highlight."
  (interactive)
  (my-cancel-later #'my-disable-paren-highlight--now)
  (ignore-errors
    ;; Dynamic face change - enable paren highlight
    (set-face-attribute 'show-paren-match nil :foreground "green" :background "#11501B" :weight 'normal :underline '(:position t))
    ;; (set-face-attribute 'show-paren-match nil :foreground "green" :background 'unspecified :weight 'normal :underline '(:position t))
    ))


(defun my-disable-paren-highlight--now ()
  ;; Dynamic face change - disable paren highlight
  (set-face-attribute 'show-paren-match nil :foreground "green" :background 'unspecified))

(defun my-disable-paren-highlight ()
  "Turn off the matching-paren highlight, after a short delay."
  (interactive)
  (my-run-later-in-buffer #'my-disable-paren-highlight--now))

;; (set-face-attribute 'show-paren-match nil :foreground 'unspecified :background 'unspecified :weight 'bold)))

(defun my-enable-symbol-overlay-highlight ()
  "Turn on symbol-overlay highlight."
  (interactive)
  (my-cancel-later #'my-disable-symbol-overlay-highlight--now)
  (when (or my-symbol-overlay-saved
            (derived-mode-p 'emacs-lisp-mode 'lisp-mode))
    (setq my-symbol-overlay-saved nil)
    (ignore-errors
      (symbol-overlay-mode 1))))


(defun my-disable-symbol-overlay-highlight--now ()
  (when (bound-and-true-p symbol-overlay-mode)
    (setq my-symbol-overlay-saved t)
    (symbol-overlay-mode 0)))

(defun my-disable-symbol-overlay-highlight ()
  "Turn off symbol-overlay highlight, after a short delay."
  (interactive)
  (my-run-later-in-buffer #'my-disable-symbol-overlay-highlight--now))


(defun my-disable-code-intelligence ()
  "Turn off highlight, electric pairs and other helpers while editing."
  (interactive)
  (when my-code-intelligence
    (my-disable-eglot-highlight)
    (unless my-code-intelligence--disabled-buffers
      (setq my-electric-pair-saved (bound-and-true-p electric-pair-mode))
      (electric-pair-mode 0))
    (ignore-errors (my-disable-symbol-overlay-highlight--now))
    (push (current-buffer) my-code-intelligence--disabled-buffers)
    (setq my-code-intelligence nil)
    ;; (message "code-intelligence is disabled.")
    ))

(defun my-enable-code-intelligence ()
  "Turn the code intelligence helpers on again."
  (interactive)
  ;; avy / deadgrep 可能在另一个 buffer 结束，恢复所有被禁用的 buffer
  (when (or my-code-intelligence--disabled-buffers (not my-code-intelligence))
    (dolist (buf (cons (current-buffer) my-code-intelligence--disabled-buffers))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          (unless my-code-intelligence
            (my-enable-eglot-highlight)
            (when my-symbol-overlay-saved
              (my-enable-symbol-overlay-highlight))
            (setq my-code-intelligence t)))))
    (setq my-code-intelligence--disabled-buffers nil)
    (electric-pair-mode (if my-electric-pair-saved 1 0))
    ;; (message "code-intelligence is enabled.")
    ))



(defun my-remove-all-highlight ()
  "Remove line, paren and eglot highlights."
  (interactive)
  (remove-all-highlight)
  (my-disable-paren-highlight)
  (my-disable-eglot-highlight))

(defun my-enable-all-highlight ()
  "Turn on paren and eglot highlights."
  (interactive)
  (my-enable-paren-highlight)
  (my-enable-eglot-highlight))



(provide 'my-toggle-code-intelligence)

;;; my-toggle-code-intelligence.el ends here
