;; -*- lexical-binding: t -*-
;;; init-wayland.el --- Wayland clipboard configuration

;; 启用剪贴板共享

;;; Code:

(setq select-enable-clipboard t)
(setq select-enable-primary t)

;; Wayland 支持
(defvar my-wl-copy-process nil)

(defun my-wl-copy (text)
  "Copy TEXT to Wayland clipboard using wl-copy."
  (setq my-wl-copy-process (make-process :name "wl-copy"
                                      :buffer nil
                                      :command '("wl-copy" "-f" "-n")
                                      :connection-type 'pipe
                                      :noquery t))
  (process-send-string my-wl-copy-process text)
  (process-send-eof my-wl-copy-process))

(defun my-wl-paste ()
  "Paste from Wayland clipboard using wl-paste."
  (if (and my-wl-copy-process (process-live-p my-wl-copy-process))
      nil
    (shell-command-to-string "wl-paste -n | tr -d \r")))

;; 如果是 Wayland，使用 wl-clipboard
(when (getenv "WAYLAND_DISPLAY")
  (setq interprogram-cut-function 'my-wl-copy)
  (setq interprogram-paste-function 'my-wl-paste))

(provide 'init-wayland)

;;; init-wayland.el ends here
