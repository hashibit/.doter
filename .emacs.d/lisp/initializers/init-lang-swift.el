;; -*- lexical-binding: t -*-
;;; init-lang-swift.el --- Swift language configuration

;;; Code:

(use-package swift-mode
  :defer t)
;; 格式化由 format-all-mode（挂在 prog-mode-hook）统一处理，走 swiftformat。

(defun my-xcode--osascript (action)
  "Run ACTION (\"build\", \"run\", \"test\") on Xcode's workspace, asynchronously."
  (let ((args (list "-e" "tell application \"Xcode\""
                    "-e" "set targetProject to active workspace document")))
    (unless (string= action "build")
      (setq args (append args (list "-e" "stop targetProject"))))
    (setq args (append args (list "-e" (concat action " targetProject")
                                  "-e" "end tell")))
    (make-process :name (concat "xcode-" action)
                  :command (cons "osascript" args)
                  :buffer nil
                  :noquery t
                  :connection-type 'pipe)))

(defun my-xcode-build()
  "Build current Xcode project."
  (interactive)
  (my-xcode--osascript "build"))

(defun my-xcode-run()
  "Run current Xcode project."
  (interactive)
  (my-xcode--osascript "run"))

(defun my-xcode-test()
  "Test current Xcode project."
  (interactive)
  (my-xcode--osascript "test"))

;; Old names, so M-x with the old name still works.
(define-obsolete-function-alias 'xcode-build #'my-xcode-build "2026-10-27")
(define-obsolete-function-alias 'xcode-run #'my-xcode-run "2026-10-27")
(define-obsolete-function-alias 'xcode-test #'my-xcode-test "2026-10-27")

(provide 'init-lang-swift)

;;; init-lang-swift.el ends here
