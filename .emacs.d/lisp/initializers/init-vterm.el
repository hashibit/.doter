;; -*- lexical-binding: t -*-
;;; init-vterm.el --- VTerm Configuration

;;; Commentary:
;;
;;  Terminal emulator configuration.  Not loaded by init.el now, and the
;;  vterm package is not installed: eat replaces it (see init-eat.el).
;;

;;; Code:

(defvar vterm-copy-mode)
(declare-function vterm-copy-mode "vterm")
(declare-function vterm-copy-mode-done "vterm")
(declare-function vterm-send-key "vterm")


;;; Commands

(defun my-vterm-copy-region (&optional _arg)
  "Copy the region, or the current line without a region."
  (interactive "p")
  (if (use-region-p)
      (kill-ring-save (region-beginning) (region-end))
    (save-excursion
      (copy-region-as-kill (line-beginning-position) (line-end-position)))))

(defun my-vterm-copy-and-exit ()
  "Copy, then leave copy mode."
  (interactive)
  (my-vterm-copy-region)
  (vterm-copy-mode -1))

(defun my-vterm-send-ctrl-c ()
  "Send C-c to the terminal."
  (interactive)
  (vterm-send-key "c" nil nil t))


;;; Buffer setup

(defun my-vterm-delete-window-on-kill ()
  "Delete this buffer's window when the buffer is killed."
  (let ((window (get-buffer-window (current-buffer))))
    (when (and window (not (one-window-p)))
      (delete-window window))))

(defun my-vterm-setup-kill-window-hook ()
  "Add `my-vterm-delete-window-on-kill' to this buffer's kill hook."
  (add-hook 'kill-buffer-hook #'my-vterm-delete-window-on-kill nil t))

(defun my-toggle-legendary-buffer-for-vterm (&optional _arg)
  "Make vterm buffers legendary, except in copy mode."
  (if (bound-and-true-p vterm-copy-mode)
      (my-remove-from-legendary-buffers '("*vterm" "*claude"))
    (my-add-to-legendary-buffers '("*vterm" "*claude")))
  (refresh-current-mode))

;; fix claude code line flickering
;; https://github.com/anthropics/claude-code/issues/247#issuecomment-3058405139
(defun my-vterm-font-setup ()
  "Configure font settings specifically for vterm buffers, workaround claude-code."

  ;; Apply ASCII replacements for vterm specifically
  (let ((tbl (or buffer-display-table (setq buffer-display-table (make-display-table)))))
    (dolist (pair
             '((#x273B . ?*) ; ✻ TEARDROP-SPOKED ASTERISK
               (#x273D . ?*) ; ✽ HEAVY TEARDROP-SPOKED ASTERISK
               (#x2722 . ?+) ; ✢ FOUR TEARDROP-SPOKED ASTERISK
               (#x2736 . ?+) ; ✶ SIX-POINTED BLACK STAR
               (#x2733 . ?*) ; ✳ EIGHT SPOKED ASTERISK
               (#x23FA . ?*) ; ⏺ RECORD BUTTON
               ))
      (aset tbl (car pair) (vector (cdr pair))))))

(defun my-vterm-nobreak-space-setup ()
  "Do not underline non-breaking spaces in this buffer."
  (face-remap-add-relative 'nobreak-space :underline nil))


;;; Scroll into copy mode

(defun my-vterm-toggle-scroll (&rest event)
  "Enter copy mode on scroll up; leave it at the bottom on scroll down."
  (when (eq major-mode 'vterm-mode)
    (let ((scroll-up (if (display-graphic-p) 'triple-wheel-up 'wheel-up))
          (scroll-down (if (display-graphic-p) 'triple-wheel-down 'wheel-down))
          (event-type (car-safe (car-safe event))))
      ;; (message "event-type: %s" event-type)
      (cond
       ((eq event-type scroll-up)
        (unless vterm-copy-mode (vterm-copy-mode 1)))
       ((eq event-type scroll-down)
        (when (and vterm-copy-mode (> (window-end) (buffer-size)))
          (vterm-copy-mode-done nil)))))))

(defun my-vterm-sync-copy-mode-on-vscroll (window &rest _)
  "After WINDOW's vscroll changes, toggle `vterm-copy-mode' in its vterm buffer."
  (let ((window (or window (selected-window))))
    (when (and (window-live-p window)
               (eq (buffer-local-value 'major-mode (window-buffer window)) 'vterm-mode))
      (with-selected-window window
        (if (> (window-end) (buffer-size))
            (when vterm-copy-mode (vterm-copy-mode-done nil))
          (vterm-copy-mode 1))))))


;;; Packages

(use-package vterm
  :ensure t
  :commands vterm
  :config
  (setq vterm-timer-delay 0.001
        vterm-max-scrollback 10000
        vterm-kill-buffer-on-exit t)

  (add-hook 'vterm-mode-hook #'my-vterm-setup-kill-window-hook)
  ;; (add-hook 'vterm-mode-hook
  ;;   (lambda ()
  ;;     (add-hook 'window-configuration-change-hook
  ;;               (lambda ()
  ;;                 (when (derived-mode-p 'vterm-mode)
  ;;                   (goto-char (point-max))))
  ;;               nil t)))
  (add-hook 'vterm-mode-hook #'my-vterm-font-setup)
  (add-hook 'vterm-mode-hook #'my-vterm-nobreak-space-setup)

  (define-prefix-command 'my-vterm-ctrl-s-key)
  (keymap-set vterm-mode-map "C-s" #'my-vterm-ctrl-s-key)

  (keymap-set vterm-copy-mode-map "s-c" #'my-vterm-copy-and-exit)

  (keymap-set vterm-copy-mode-map "<return>" #'vterm-copy-mode)
  (keymap-set vterm-copy-mode-map "q" #'vterm-copy-mode)
  (keymap-set vterm-copy-mode-map "<escape>" #'vterm-copy-mode)
  (keymap-set vterm-copy-mode-map ";" #'scroll-up-command)
  (keymap-set vterm-copy-mode-map "'" #'scroll-down-command)

  (keymap-set vterm-mode-map "C-s [" #'vterm-copy-mode)
  (keymap-set vterm-copy-mode-map "y" #'vterm-copy-mode-done)
  (keymap-set vterm-copy-mode-map "M-w" #'vterm-copy-mode-done)

  (keymap-set vterm-mode-map "C-s-c" #'my-vterm-send-ctrl-c)
  (keymap-set vterm-mode-map "M-i" #'er/expand-region)
  (keymap-set vterm-mode-map "M-h" #'windmove-left)
  (keymap-set vterm-mode-map "M-l" #'windmove-right)

  (add-hook 'vterm-copy-mode-hook #'my-toggle-legendary-buffer-for-vterm)
  (add-hook 'window-buffer-change-functions #'my-toggle-legendary-buffer-for-vterm)

  ;; run first time
  (my-toggle-legendary-buffer-for-vterm)
  (keymap-unset vterm-mode-map "M-`")
  (keymap-unset vterm-mode-map "M-:"))

(use-package multi-vterm
  :ensure t
  :config
  (setq multi-vterm-dedicated-window-height-percent 90))

;; 当用户主动滚动到上方时，自动进入 copy mode，从而阻止自动刷新终端
(with-eval-after-load 'pixel-scroll
  (advice-add 'pixel-scroll-precision :after #'my-vterm-toggle-scroll))

;; 原来这里用同名 defun 重新定义了 me/vterm-toggle-scroll（覆盖上面的版本），
;; 现在改名，只在 vterm 加载后才挂到 set-window-vscroll 上
(with-eval-after-load 'vterm
  (advice-add 'set-window-vscroll :after #'my-vterm-sync-copy-mode-on-vscroll))


(provide 'init-vterm)

;;; init-vterm.el ends here
