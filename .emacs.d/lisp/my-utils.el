;; -*- lexical-binding: t -*-
;;; my-utils.el --- Personal utility functions

(require 'cl-lib)
(require 'seq)
(require 'f)

(require 'my-visual-line)
(require 'my-motion)
(require 'my-editing)
(require 'my-hideshow)
(require 'my-window-buffer)
(require 'my-eldoc-box)
(require 'my-text-boxes)



(defun my-util-read-fmt-content (filepath)
  "Read and format content from FILEPATH."
  (interactive)
  (let ((file-content (f-read-text filepath)))
    (with-temp-buffer
      (emacs-lisp-mode)
      ;; (rename-buffer "tmp.el" t)
      ;; (set-auto-mode)
      ;; (message "%s" (buffer-mode))
      (insert file-content)
      (font-lock-ensure)
      (buffer-string))))



;; ;; copy from elisp-eldoc-var-docstring-with-value
;; (defun my-elisp-eldoc-var-docstring-with-value (callback &rest _)
;;   (when-let* ((cs (elisp--current-symbol)))
;;     (when (and (boundp cs)
;; 	           ;; nil and t are boundp!
;; 	           (not (null cs))
;; 	           (not (eq cs t)))
;;       (funcall callback
;; 	           (format "%s"
;; 		               (let* ((doc
;;                                (describe-function cs)
;;                                ;; (documentation-property
;;                                ;;      cs 'variable-documentation t)
;;                                )
;; 			                  (more (- (length doc) 1000)))
;;                          (message "doc: %s" doc)
;; 			             (concat (propertize
;; 				                  (string-limit (if (string= doc "nil")
;; 						                            "Undocumented."
;; 						                          doc)
;; 					                            1000)
;; 				                  'face 'font-lock-doc-face)
;; 				                 (when (> more 0)
;; 				                   (format "[%sc more]" more)))))
;; 	           :thing cs
;; 	           :face 'font-lock-variable-name-face))))



(defun which-active-modes ()
  "Give a message of which minor modes are enabled in the current buffer."
  (interactive)
  (message "Active modes are %s"
           (append local-minor-modes global-minor-modes)))



;; Check if system is Darwin/Mac OS X
(defun my-system-type-is-darwin ()
  "Return true if system is darwin-based (Mac OS X)"
  (eq system-type 'darwin))

;; Check if system is Microsoft Windows
(defun my-system-type-is-windows ()
  "Return true if system is Windows-based (at least up to Win7)"
  (eq system-type 'windows-nt))

;; Check if system is GNU/Linux
(defun my-system-type-is-gnu ()
  "Return true if system is GNU/Linux-based"
  (eq system-type 'gnu/linux))



(defun my-show-file-name ()
  "Show the current buffer's file name."
  (interactive)
  (if-let* ((file (buffer-file-name)))
      (message "%s" file)
    (message "Buffer %s is not visiting a file" (buffer-name))))



(defun my-copied-content-is-end-of-newline ()
  "Check if copied content ends with newline."
  (interactive)
  (string-suffix-p "\n" (current-kill 0 'DONT-MOVE)))



(defun buffer-mode (&optional buffer-or-name)
  "Returns the major mode associated with a buffer.
If buffer-or-name is nil return current buffer's mode."
  (buffer-local-value 'major-mode
                      (if buffer-or-name
                          (get-buffer buffer-or-name)
                        (current-buffer))))



;; Source: https://www.emacswiki.org/emacs/misc-cmds.el
(defun my-revert-buffer-no-confirm ()
  "Revert buffer without confirmation."
  (interactive)
  (revert-buffer :ignore-auto :noconfirm)
  (refresh-current-mode))



(defun my-M-x ()
  (interactive)
  (refresh-current-mode)
  (counsel-M-x))

(defun my-occur ()
  (interactive)
  (if (region-active-p)
      (let* ((start (region-beginning))
             (end (region-end))
             (input (buffer-substring-no-properties start end)))
        (deactivate-mark)
        (counsel-grep input))
    (counsel-grep)))

(defun my-rg-at-point ()
  (interactive)
  (if (region-active-p)
      (let* ((start (region-beginning))
             (end (region-end))
             (input (buffer-substring-no-properties start end)))
        (deactivate-mark)
        (counsel-rg (concat input " ")))
    (counsel-rg)))

(defun my-find-files ()
  (interactive)
  (counsel-find-file))

(defun my-mark-ring ()
  (interactive)
  (counsel-mark-ring)
  (recenter))



(defun my-joindirs (root &rest dirs)
  "Joins a series of directories together, like Python's os.path.join,
  (dotemacs-joindirs \"/tmp\" \"a\" \"b\" \"c\") => /tmp/a/b/c"
  (expand-file-name (apply #'file-name-concat root dirs)))



(defun bury-compile-buffer-if-successful (buffer string)
  "Bury a compilation buffer if succeeded without warnings "
  (when (and
         (buffer-live-p buffer)
         (string-match-p "compilation" (buffer-name buffer))
         (string-match-p "finished" string)
         ;; (not
         ;;   (with-current-buffer buffer
         ;;     (goto-char (point-min))
         ;;     (search-forward "warning" nil t)))
         )
    (run-with-timer 1 nil
                    (lambda (buf)
                      (delete-windows-on buf)
                      (bury-buffer buf)
                      ;; (switch-to-prev-buffer (get-buffer-window buf) 'kill)
                      )
                    buffer)))



(defun my-save-buffer ()
  "delete current word, goto insert mode"
  (interactive)
  (save-buffer)
  (my-init-god-mode-for-new-buffer)
  ;; (my-quit-mc-mode-if-need)
  )

(defun my-save-buffer-without-hooks ()
  "delete current word, goto insert mode"
  (interactive)
  (save-buffer-without-hooks)
  (my-init-god-mode-for-new-buffer)
  ;; (my-quit-mc-mode-if-need)
  )



(defun my-blink-search()
  (interactive)
  (blink-search-restart-process)
  (blink-search))


(defun advise-once (symbol where function &optional props)
  "Add FUNCTION as WHERE advice to SYMBOL, removed after the first call."
  (letrec ((remover (lambda (&rest _)
                      (advice-remove symbol function)
                      (advice-remove symbol remover))))
    (advice-add symbol :after remover)
    (advice-add symbol where function props)))



(defun upward-find-file (filename &optional startdir)
  "Move up directories until we find a certain filename. If we
  manage to find it, return the containing directory. Else if we
  get to the toplevel directory and still can't find it, return
  nil. Start at startdir or . if startdir not given"
  (when-let* ((dir (locate-dominating-file
                    (expand-file-name (or startdir "."))
                    filename)))
    (directory-file-name (expand-file-name dir))))



(defun start-zsh-term()
  (interactive)
  (vterm))


(defun toggle-continuation-fringe-indicator ()
  (interactive)
  (setq-default
   fringe-indicator-alist
   (if (assq 'continuation fringe-indicator-alist)
       (delq (assq 'continuation fringe-indicator-alist) fringe-indicator-alist)
     (cons '(continuation right-curly-arrow left-curly-arrow) fringe-indicator-alist))))

(defun my-toggle-truncate-lines-and-word-wrap()
  (interactive)
  (toggle-truncate-lines)
  (toggle-word-wrap))

(defun compileandrun()
  (interactive)
  (let* ((src (file-name-nondirectory (buffer-file-name)))
         (exe (file-name-sans-extension src)))
    (compile (concat "g++ " src " -std=c++20 " " -o " exe " && ./" exe))))


(defun save-buffer-without-hooks ()
  "Save current buffer without running any before/after save hooks."
  (interactive)
  (let ((before-save-hook nil)
        (after-save-hook nil))
    (save-buffer)))


(defun my-set-buffer-use-tabs ()
  (interactive)
  (setq-local indent-tabs-mode t
              tab-width 4))

(defun my-set-buffer-use-space ()
  (interactive)
  (setq-local indent-tabs-mode nil
              tab-width 4))

(defun my-untabify-buffer ()
  "将当前缓冲区中的所有 Tab 替换为 4 个空格。"
  (interactive)
  (my-set-buffer-use-space)
  (untabify (point-min) (point-max)))

(defun my-tabify-buffer ()
  "将当前缓冲区中的所有 Tab 替换为 4 个空格。"
  (interactive)
  (my-set-buffer-use-tabs)
  (tabify (point-min) (point-max)))


(defun my-hide-title-bar ()
  (interactive)
  (modify-frame-parameters nil '((undecorated . t)))
  (my-M-x))

(defun my-show-title-bar ()
  (interactive)
  (modify-frame-parameters nil '((undecorated . nil)))
  (my-M-x))

(defun my-set-proxy (&optional ip port)
  "Set HTTP/HTTPS proxy environment variables.
If called interactively, prompt for IP and port.
Default port is 9910 if not provided."
  ;; 如果是交互式调用（M-x），提示用户输入
  (interactive
   (list (read-string "Proxy IP (e.g. 127.0.0.1): " "127.0.0.1")
         (read-number "Proxy Port (e.g. 9910): " 9910)))

  ;; 确保 port 是整数
  (unless (integerp port)
    (setq port (string-to-number (format "%s" (or port "")))))

  ;; 确保默认值
  (unless (> port 0)
    (setq port 9910))
  (unless (> (length ip) 0)
    (setq ip "127.0.0.1"))

  ;; 构造代理 URL
  (let ((proxy-url (format "http://%s:%d" ip port))
        (no-proxy-list "localhost,127.0.0.1,::1,192.168.0.0/16,172.16.0.0/12,10.0.0.0/8"))

    ;; 设置大小写两种形式（有些工具只认大写或小写）
    (dolist (var '("http_proxy" "https_proxy" "HTTP_PROXY" "HTTPS_PROXY"))
      (setenv var proxy-url))

    (dolist (var '("no_proxy" "NO_PROXY"))
      (setenv var no-proxy-list))

    (message "Proxy set to: %s (bypass: %s)" proxy-url no-proxy-list)))

(defun my-unset-proxy()
  (interactive)
  (dolist (var '("http_proxy" "https_proxy" "HTTP_PROXY" "HTTPS_PROXY"
                 "no_proxy" "NO_PROXY"))
    (setenv var nil)))



(defun run-command-in-directory (dir cmd &rest args)
  "Run a command in the specified directory.
If DIR is nil, use `default-directory'.
Return trimmed stdout if success, nil otherwise."
  (let ((default-directory (or dir default-directory)))
    ;; 不用 process-lines：它会把 stderr 混进输出
    (with-temp-buffer
      (when (eql 0 (condition-case nil
                       (apply #'call-process cmd nil '(t nil) nil args)
                     (file-missing nil)))
        (string-trim (buffer-string))))))



(defun cmake-download-cpm()
  (interactive)
  (let* ((cmake-dir (file-name-concat (cmake-project-find-root-directory) "cmake"))
         (cpm-file-path (file-name-concat cmake-dir "CPM.cmake")))
    (unless (file-exists-p cpm-file-path)
      (make-directory cmake-dir t)
      (url-copy-file
       "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.42.0/CPM.cmake"
       cpm-file-path t))
    (message "saved to %s" cpm-file-path)))



(provide 'my-utils)
