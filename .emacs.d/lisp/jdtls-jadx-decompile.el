;;; jdtls-jadx-decompile.el --- Decompiled .class files with JADX for jdtls -*- lexical-binding: t; -*-

;; Author: Your Name
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: java, tools, lisp

;;; Commentary:

;; Integrates JADX decompiler with jdtls to view .class files in Emacs.
;; Automatically decompiles JAR-contained classes and displays Java source.

;;; Code:

;; 函数统一用 jadx-jdt- 前缀，避免与 java-decompile.el 中的 jdtls-* 同名函数冲突

(require 'cl-lib)
(require 'subr-x)

(defun jadx-jdt-extract-url (path)
  "Extract jdt: URL from a mixed path like:
/full/path/to/model/jdt:/contents/jar.jar?query..."
  (when path
    (string-match "jdt:/contents/[^?\"']+\\.jar?[^?\"']*" path)
    (match-string 0 path)))

(defun jadx-jdt-classpath-to-filename (class-path)
  "Convert class path like 'com.xme.ai.LLMCaller' to file name 'LLMCaller.java'."
  (when (string-match "\\([^./]+\\)\\'" class-path)
    (concat (match-string 1 class-path) ".java")))

(defun jadx-jdt-decompile-async ()
  "Decompile current JDT virtual buffer asynchronously using JADX."
  (interactive)
  (unless (derived-mode-p 'java-ts-mode 'java-mode)
    (user-error "Not a Java buffer"))

  (let* ((full-path buffer-file-name)
          (jdt-url (and full-path (jadx-jdt-extract-url full-path))))
    (unless jdt-url
      (user-error "Not a valid jdt: virtual file (no jdt:/contents found)"))

    (unless (string-match "^jdt:/contents/\\([^/]+\\.jar\\)\\(?:\\?\\|/\\)\\(.+\\)" jdt-url)
      (user-error "Invalid jdt URL format: %s" jdt-url))

    (let* ((jar-path (match-string 1 jdt-url))
            (rest-part (match-string 2 jdt-url))
            (decoded-rest (url-unhex-string rest-part))
            class-path)

      ;; 提取类名
      (cond
        ((string-match "[<(]\\([a-zA-Z0-9_.$]+\\)\\.class" decoded-rest)
          (setq class-path (match-string 1 decoded-rest)))
        ((string-match "\\([a-zA-Z0-9_.$/]+\\)\\.class\\'" decoded-rest)
          (setq class-path (replace-regexp-in-string "/" "." (match-string 1 decoded-rest) 'fixed-case)))
        (t
          (user-error "Cannot extract class name from: %s" decoded-rest)))

      ;; ✅ 设置缓存和临时目录
      (let* ((cache-dir (expand-file-name (concat user-emacs-directory "jdtls-jadx-cache/")))
              (safe-class-path (replace-regexp-in-string "[^a-zA-Z0-9._-]" "_" class-path t t))
              (cache-file (expand-file-name (concat safe-class-path ".java") cache-dir))
              (temp-dir (make-temp-file "jadx-" 'directory)))

        (make-directory cache-dir t)

        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (format "// Decompiling with JADX...\n"))
          (insert (format "// JAR: %s\n" (file-name-nondirectory jar-path)))
          (insert (format "// Class: %s\n" class-path))
          (insert "\n// Loading... 0%%\n"))

        ;; ✅ 关键：临时设置 default-directory 为合法路径
        (let ((default-directory temporary-file-directory))

          (let ((proc (start-process
                        "jadx-decompile" "*JADX-Output*"
                        "jadx" "-d" temp-dir "--quiet" jar-path))
                (target-buffer (current-buffer)))
            (set-process-sentinel
              proc
              (lambda (process event)
                ;; jadx 有错误时也会返回非 0，但通常仍会生成部分源码
                (when (memq (process-status process) '(exit signal))
                  (unless (string-prefix-p "finished" event)
                    (message "JADX: %s" (string-trim event)))
                  (jadx-jdt-process-result
                    temp-dir cache-file class-path target-buffer))))))))))

(cl-defun jadx-jdt-process-result (temp-dir cache-file class-path target-buffer)
  "Process JADX output, find source, cache it, and insert into TARGET-BUFFER."
  (let* ((sources-dir (concat temp-dir "/sources"))
          (expected-filename (jadx-jdt-classpath-to-filename class-path))
          java-file)

    ;; Check if sources directory exists
    (unless (file-directory-p sources-dir)
      (message "JADX error: No sources directory: %s" sources-dir)
      (delete-directory temp-dir t)
      (when (buffer-live-p target-buffer)
        (with-current-buffer target-buffer
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert (format "// JADX FAILED: No sources directory: %s\n" sources-dir))
            (insert (format "// Make sure 'jadx' is installed and runnable.\n"))
            (insert (format "// You can install it via: brew install jadx\n")))))
      (cl-return-from jadx-jdt-process-result))

    ;; Recursively search for the expected Java file
    (let ((files (directory-files-recursively sources-dir (concat "\\b" (regexp-quote expected-filename) "$"))))
      (setq java-file (car files)))

    (cond
      (java-file
        ;; Found file: cache and insert
        (copy-file java-file cache-file t) ; overwrite if exists

        (when (buffer-live-p target-buffer)
          (with-current-buffer target-buffer
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert (format "// Decompiled with JADX\n"))
              (insert (format "// Source: %s\n" (file-name-nondirectory cache-file)))
              (insert (format "// Class: %s\n" class-path))
              (insert "\n"))))

        ;; Load content asynchronously to avoid blocking.
        ;; 从 cache-file 读取：temp-dir 在本函数结束时就被删除了
        (run-with-timer 0.05 nil
          (lambda (java-file target-buffer)
            (with-temp-buffer
              (condition-case err
                (progn
                  (insert-file-contents java-file)
                  (let ((source-code (buffer-string)))
                    (when (buffer-live-p target-buffer)
                      (with-current-buffer target-buffer
                        (let ((inhibit-read-only t))
                          (goto-char (point-max))
                          (delete-region (line-beginning-position) (point))
                          (insert source-code)
                          ;; ✅ Now set buffer to read-only
                          (setq-local buffer-read-only t)
                          (setq-local buffer-offer-save nil)
                          (setq-local make-backup-files nil)
                          (setq-local auto-save-default nil)
                          (setq-local cursor-type nil) ; optional: disable cursor
                          (java-ts-mode)
                          (message "Decompilation completed: %s" java-file))))))
                (file-error
                  (when (buffer-live-p target-buffer)
                    (with-current-buffer target-buffer
                      (let ((inhibit-read-only t))
                        (goto-char (point-max))
                        (delete-region (line-beginning-position) (point))
                        (insert (format "\n// Error: Failed to read decompiled file: %s\n" err)))))))))
          cache-file target-buffer))

      (t
        ;; File not found
        (message "JADX error: Java file not found for class: %s (looked for %s)" class-path expected-filename)
        (when (buffer-live-p target-buffer)
          (with-current-buffer target-buffer
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert (format "// JADX FAILED: Could not find %s\n" expected-filename))
              (insert (format "// Searched in: %s\n" sources-dir))
              (insert (format "// Class: %s\n" class-path))
              (insert "// Possible reasons:\n")
              (insert "// - Class is obfuscated\n")
              (insert "// - JADX failed silently\n")
              (insert "// - Incorrect class path parsing\n")
              (insert "\n// Check *JADX-Output* buffer for details.\n"))))))

    ;; Always clean up temp dir
    (delete-directory temp-dir t)))

(provide 'jdtls-jadx-decompile)
;;; jdtls-jadx-decompile.el ends here
