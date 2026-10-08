;;; early-init.el --- Loaded before the package system and first frame -*- lexical-binding: t -*-

;;; Startup performance
;; Defer GC during startup; init.el restores a sane threshold afterwards.
(setq gc-cons-threshold most-positive-fixnum
  gc-cons-percentage 0.6)

;; Larger reads from subprocesses (LSP servers etc.); default is 64 KiB.
(setq read-process-output-max (* 1024 1024))

;; Packages are activated explicitly by `package-initialize' in init.el.
(setq package-enable-at-startup nil)

;; Keep native-comp warnings out of the way.
(setq native-comp-async-report-warnings-errors 'silent)

;;; Frame UI
;; Set these before the first frame is drawn to avoid flicker.
(dolist (param '((undecorated . t)
                  (vertical-scroll-bars . nil)
                  (left-fringe . 0)
                  (right-fringe . 0)
                  (fullscreen . maximized)
                  (tool-bar-lines . 0)
                  (menu-bar-lines . 0)))
  (add-to-list 'default-frame-alist param))

(setq frame-inhibit-implied-resize t)

;;; early-init.el ends here
