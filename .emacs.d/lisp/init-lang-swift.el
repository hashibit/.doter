;; -*- lexical-binding: t -*-
;;; init-lang-swift.el --- Swift language configuration

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

(defun xcode-build()
  "Build current Xcode project."
  (interactive)
  (my-xcode--osascript "build"))

(defun xcode-run()
  "Run current Xcode project."
  (interactive)
  (my-xcode--osascript "run"))

(defun xcode-test()
  "Test current Xcode project."
  (interactive)
  (my-xcode--osascript "test"))

(provide 'init-lang-swift)

;;; init-lang-swift.el ends here
