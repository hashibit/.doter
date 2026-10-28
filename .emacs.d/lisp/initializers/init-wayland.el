;; -*- lexical-binding: t -*-
;;; init-wayland.el --- Wayland clipboard configuration

;; 启用剪贴板共享

;;; Code:

(setq select-enable-clipboard t)
(setq select-enable-primary t)

;; Wayland 支持
(defvar wl-copy-process nil)

(defun wl-copy (text)
  "Copy TEXT to Wayland clipboard using wl-copy."
  (setq wl-copy-process (make-process :name "wl-copy"
                                      :buffer nil
                                      :command '("wl-copy" "-f" "-n")
                                      :connection-type 'pipe
                                      :noquery t))
  (process-send-string wl-copy-process text)
  (process-send-eof wl-copy-process))

(defun wl-paste ()
  "Paste from Wayland clipboard using wl-paste."
  (if (and wl-copy-process (process-live-p wl-copy-process))
      nil
    (shell-command-to-string "wl-paste -n | tr -d \r")))

;; 如果是 Wayland，使用 wl-clipboard
(when (getenv "WAYLAND_DISPLAY")
  (setq interprogram-cut-function 'wl-copy)
  (setq interprogram-paste-function 'wl-paste))

(provide 'init-wayland)

;;; init-wayland.el ends here
