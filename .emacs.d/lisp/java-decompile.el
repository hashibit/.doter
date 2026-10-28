;; java-decompile.el --- Java class decompilation utilities  -*- lexical-binding: t -*-
;;
;; Author: Your Name
;; Description: JADX-based Java decompilation for JDT virtual files
;;

;;; Code:

(defvar jdtls-jadx-cache-dir (locate-user-emacs-file ".local/jadx-cache")
  "Directory to cache JADX decompilation results.")

(defun jdtls-parse-jdt-uri (uri)
  "Parse JDT URI to extract JAR path and class path."
  (message "DEBUG: Parsing JDT URI: %s" uri)
  
  ;; Extract JDT URI part if it's embedded in a file path
  (let ((jdt-uri (if (string-match "\\(jdt:/contents/.*\\)" uri)
                     (match-string 1 uri)
                   uri)))
    (message "DEBUG: Extracted JDT URI: %s" jdt-uri)
    
    (cond
     ;; Pattern for complex JDT URIs with query params
     ((string-match "jdt:/contents/\\([^/]+\\)/\\([^?]+\\)\\.class\\?.*" jdt-uri)
      (let* ((jar-name (match-string 1 jdt-uri))
             (class-path-raw (match-string 2 jdt-uri))
             (class-path (replace-regexp-in-string "/" "." class-path-raw))
             (jar-path (jdtls-find-jar-by-name jar-name)))
        (message "DEBUG: Extracted jar-name=%s, class-path=%s" jar-name class-path)
        (list :jar-path jar-path :class-path class-path :jar-name jar-name)))
     
     ;; Pattern for JDT LSP URIs: jdt://contents/jar-file-path/class-path.class
     ((string-match "jdt://contents/\\([^/]+\\)/\\(.*\\)\\.class" jdt-uri)
      (let* ((jar-name (match-string 1 jdt-uri))
             (class-path-raw (match-string 2 jdt-uri))
             (class-path (replace-regexp-in-string "/" "." class-path-raw))
             (jar-path (jdtls-find-jar-by-name jar-name)))
        (message "DEBUG: Extracted jar-name=%s, class-path=%s" jar-name class-path)
        (list :jar-path jar-path :class-path class-path :jar-name jar-name)))
     
     ;; Pattern without query params
     ((string-match "jdt:/contents/\\([^/]+\\)/\\(.*\\)\\.class" jdt-uri)
      (let* ((jar-name (match-string 1 jdt-uri))
             (class-path-raw (match-string 2 jdt-uri))
             (class-path (replace-regexp-in-string "/" "." class-path-raw))
             (jar-path (jdtls-find-jar-by-name jar-name)))
        (message "DEBUG: Extracted jar-name=%s, class-path=%s" jar-name class-path)
        (list :jar-path jar-path :class-path class-path :jar-name jar-name)))
     
     (t 
      (message "DEBUG: No pattern matched for URI: %s" jdt-uri)
      (list :jar-path nil :class-path nil :jar-name nil)))))

(defun jdtls-find-jar-by-name (jar-name)
  "Find JAR file by name in common locations."
  (let ((search-paths (list
                       "~/.m2/repository"
                       "~/.gradle/caches"
                       "/usr/share/java"
                       "/opt/java"
                       ;; Add current project deps directories
                       "./deps"
                       "../deps"
                       "../../deps"
                       "./lib"
                       "../lib")))
    (catch 'found
      (dolist (base-path search-paths)
        (let ((expanded-path (expand-file-name base-path)))
          (when (file-directory-p expanded-path)
            (condition-case err
                (let ((jar-files (directory-files-recursively 
                                  expanded-path
                                  (concat (regexp-quote jar-name) "$"))))
                  (when jar-files
                    (throw 'found (car jar-files))))
              (error
               (message "Warning: Error searching in %s: %s" expanded-path err))))))
      (message "JAR file not found: %s. Searched in %s" jar-name search-paths)
      nil)))

(defun jdtls-jadx-decompile-async ()
  "Asynchronous JADX decompilation with caching to avoid UI blocking."
  (interactive)
  (when (and buffer-file-name
             (string-match-p "jdt:" buffer-file-name))
    (let* ((uri buffer-file-name)
           ;; Extract JAR path and class path from JDT URI
           (parsed-uri (jdtls-parse-jdt-uri uri))
           (jar-path (plist-get parsed-uri :jar-path))
           (class-path (plist-get parsed-uri :class-path))
           (jar-mtime (when (and jar-path (file-exists-p jar-path))
                        (file-attribute-modification-time (file-attributes jar-path))))
           (cache-key (when (and jar-path class-path jar-mtime)
                        (md5 (concat jar-path ":" class-path ":" (format-time-string "%s" jar-mtime)))))
           (cache-file (when cache-key
                         (concat jdtls-jadx-cache-dir "/" cache-key ".java")))
           (target-buffer (current-buffer)))

      (cond
       ((not jar-path)
        (message "Could not find JAR file from JDT URI: %s" uri)
        (when (buffer-live-p target-buffer)
          (with-current-buffer target-buffer
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert "// Could not find JAR file\n")
              (insert (format "// JDT URI: %s\n" uri))))))
       ((not class-path)
        (message "Could not extract class path from JDT URI: %s" uri)
        (when (buffer-live-p target-buffer)
          (with-current-buffer target-buffer
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert "// Could not extract class path\n")
              (insert (format "// JDT URI: %s\n" uri))))))
       ((not (file-exists-p jar-path))
        (message "JAR file does not exist: %s" jar-path)
        (when (buffer-live-p target-buffer)
          (with-current-buffer target-buffer
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert "// JAR file does not exist\n")
              (insert (format "// Expected path: %s\n" jar-path))))))
       (t

        (condition-case err
            (make-directory jdtls-jadx-cache-dir t)
          (error
           (message "Failed to create cache directory: %s" err)
           (setq cache-file nil)))

        ;; Check cache first
        (if (and cache-file (file-exists-p cache-file))
            (jdtls-load-from-cache cache-file jar-path class-path)

          ;; Show loading message immediately
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert (format "// Decompiling with JADX (first time, will be cached)...\n"))
            (insert (format "// JAR: %s\n" (file-name-nondirectory jar-path)))
            (insert (format "// Class: %s\n\n" class-path))
            (insert "// Please wait, JADX is running in background...\n")
            (insert "// You can continue using Emacs while this runs.\n"))

          ;; Start async decompilation
          (message "DEBUG: About to start JADX with jar-path=%s, class-path=%s" jar-path class-path)
          (jdtls-start-jadx-process jar-path cache-file class-path target-buffer)))))))

(defun jdtls-load-from-cache (cache-file jar-path class-path)
  "Load decompiled content from cache asynchronously."
  (message "Loading from cache...")
  (let ((target-buffer (current-buffer)))
    ;; Show loading message immediately
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (format "// Decompiled with JADX (cached) from: %s\n"
                      (file-name-nondirectory jar-path)))
      (insert (format "// Class: %s\n\n" class-path))
      (insert "// Loading from cache...\n"))

    ;; Load content asynchronously
    (run-with-timer 0.01 nil
                    (apply-partially
                     (lambda (cache-file target-buffer)
                       (let ((java-source (with-temp-buffer
                                            (insert-file-contents cache-file)
                                            (buffer-string))))
                         (when (buffer-live-p target-buffer)
                           (with-current-buffer target-buffer
                             (let ((inhibit-read-only t))
                               (goto-char (point-max))
                               (delete-region (pos-bol) (point))  ; Remove "Loading..." line
                               (jdtls-insert-large-content java-source target-buffer))))))
                     cache-file target-buffer))))

(defun jdtls-start-jadx-process (jar-path cache-file class-path target-buffer)
  "Start JADX process asynchronously."
  (unless (executable-find "jadx")
    (error "JADX is not installed or not in PATH. Please install JADX first"))
  
  (let ((temp-dir (make-temp-file "jadx-" t))
        (default-directory (expand-file-name "~"))) ; Set working directory to home
    (message "Starting JADX decompilation..., temp-dir: %s" temp-dir)

    ;; Use async process with minimal output
    (let ((proc (start-process "jadx-decompile" "*JADX-Output*"
                               "jadx" "-d" temp-dir "--quiet" jar-path)))
      (set-process-sentinel proc
                            `(lambda (process event)
                               (cond
                                ((string= event "finished\n")
                                 (jdtls-handle-jadx-completion ,temp-dir ,cache-file ,class-path ,target-buffer))
                                ((string-match-p "exited abnormally" event)
                                 (message "JADX decompilation failed: %s" event)
                                 (when (buffer-live-p ,target-buffer)
                                   (with-current-buffer ,target-buffer
                                     (let ((inhibit-read-only t))
                                       (erase-buffer)
                                       (insert "// JADX decompilation failed\n")
                                       (insert "// Please check that JADX is properly installed\n")
                                       (insert "// Error: " event "\n"))))
                                 (delete-directory ,temp-dir t))))))))

(defun jdtls-handle-jadx-completion (temp-dir cache-file class-path target-buffer)
  "Handle JADX completion and update buffer."
  ;; Use timer to avoid blocking UI
  (run-with-timer 0.1 nil
                  (apply-partially 'jdtls-process-jadx-result
                                   temp-dir cache-file class-path target-buffer)))

(defun jdtls-process-jadx-result (temp-dir cache-file class-path target-buffer)
  "Process JADX result and update target buffer."
  ;; Wait a bit for JADX to finish writing files
  (run-with-timer 0.5 nil
                  (apply-partially 'jdtls-process-jadx-result-delayed
                                   temp-dir cache-file class-path target-buffer)))

(defun jdtls-process-jadx-result-delayed (temp-dir cache-file class-path target-buffer)
  "Process JADX result after delay to avoid race conditions."
  (let* ((sources-dir (concat temp-dir "/sources"))
         ;; Convert class path to file path
         (class-file-path (concat sources-dir "/" (replace-regexp-in-string "\\." "/" class-path) ".java")))

    (message "DEBUG: Looking for class file at: %s" class-file-path)
    
    ;; Try to find the Java file with retry mechanism
    (jdtls-find-java-file-with-retry class-file-path class-path sources-dir 
                                     cache-file target-buffer temp-dir 0)))

(defun jdtls-find-java-file-with-retry (class-file-path class-path sources-dir 
                                                        cache-file target-buffer temp-dir retry-count)
  "Find Java file with retry mechanism to handle race conditions."
  (let ((max-retries 5))
    (cond
     ;; Found exact file
     ((file-exists-p class-file-path)
      (message "DEBUG: Found exact file: %s" class-file-path)
      (jdtls-load-java-file class-file-path cache-file target-buffer temp-dir))
     
     ;; Search by class name
     ((file-directory-p sources-dir)
      (let* ((class-file-name (car (last (split-string class-path "\\."))))
             (java-files (directory-files-recursively sources-dir 
                                                      (concat (regexp-quote class-file-name) "\\.java$"))))
        (message "DEBUG: Found java files by name search: %s" java-files)
        (if java-files
            (jdtls-load-java-file (car java-files) cache-file target-buffer temp-dir)
          ;; Retry if not found and haven't exceeded max retries
          (if (< retry-count max-retries)
              (progn
                (message "DEBUG: Retrying in 0.5s (attempt %d/%d)" (1+ retry-count) max-retries)
                (run-with-timer 0.5 nil
                                (apply-partially 'jdtls-find-java-file-with-retry
                                                 class-file-path class-path sources-dir 
                                                 cache-file target-buffer temp-dir (1+ retry-count))))
            (jdtls-handle-decompilation-failure class-path target-buffer temp-dir)))))
     
     ;; Sources directory doesn't exist, retry or fail
     ((< retry-count max-retries)
      (message "DEBUG: Sources dir not ready, retrying in 0.5s (attempt %d/%d)" (1+ retry-count) max-retries)
      (run-with-timer 0.5 nil
                      (apply-partially 'jdtls-find-java-file-with-retry
                                       class-file-path class-path sources-dir 
                                       cache-file target-buffer temp-dir (1+ retry-count))))
     
     ;; Max retries exceeded
     (t
      (jdtls-handle-decompilation-failure class-path target-buffer temp-dir)))))

(defun jdtls-load-java-file (java-file cache-file target-buffer temp-dir)
  "Load Java file content into target buffer."
  (condition-case err
      (progn
        ;; Save to cache
        (copy-file java-file cache-file)

        ;; Update target buffer first, then load content asynchronously
        (when (buffer-live-p target-buffer)
          (with-current-buffer target-buffer
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert (format "// Decompiled with JADX from: %s\n"
                              (file-name-nondirectory java-file)))
              (insert (format "// Class: %s\n\n" (file-name-base java-file)))
              (insert "// Loading content...\n")))

          ;; Load content asynchronously
          (run-with-timer 0.05 nil
                          (apply-partially
                           (lambda (java-file target-buffer temp-dir)
                             (let ((java-source (with-temp-buffer
                                                  (insert-file-contents java-file)
                                                  (buffer-string))))
                               (when (buffer-live-p target-buffer)
                                 (with-current-buffer target-buffer
                                   (let ((inhibit-read-only t))
                                     (goto-char (point-max))
                                     (delete-region (pos-bol) (point))  ; Remove "Loading..." line
                                     (jdtls-insert-large-content java-source target-buffer))))
                               ;; Cleanup temp directory
                               (delete-directory temp-dir t)))
                           java-file target-buffer temp-dir))))
    (error
     (message "Error loading Java file: %s" err)
     (jdtls-handle-decompilation-failure "Unknown" target-buffer temp-dir))))

(defun jdtls-handle-decompilation-failure (class-path target-buffer temp-dir)
  "Handle decompilation failure by showing error message."
  (message "JADX decompilation failed for class: %s" class-path)
  (when (buffer-live-p target-buffer)
    (with-current-buffer target-buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "// JADX decompilation failed\n")
        (insert (format "// Class: %s\n" class-path))
        (insert "// This might happen if the class is not in the JAR\n")
        (insert "// or if JADX failed to decompile it.\n"))))
  ;; Cleanup
  (when (file-directory-p temp-dir)
    (delete-directory temp-dir t)))

(defun jdtls-insert-large-content (content target-buffer)
  "Insert large content without blocking UI."
  (when (buffer-live-p target-buffer)
    (with-current-buffer target-buffer
      (let ((inhibit-read-only t))
        (if (< (length content) 5000)
            ;; Small content, insert directly
            (progn
              (insert content)
              (jdtls-finalize-buffer target-buffer))

          ;; Large content, insert in very small chunks
          (let ((chunk-size 1000)
                (pos 0))
            (jdtls-insert-content-chunk content target-buffer pos chunk-size)))))))

(defun jdtls-insert-content-chunk (content target-buffer pos chunk-size)
  "Insert content chunk by chunk with progress indication."
  (when (buffer-live-p target-buffer)
    (with-current-buffer target-buffer
      (let ((end-pos (min (+ pos chunk-size) (length content)))
            (progress (/ (* pos 100) (length content)))
            (inhibit-read-only t))

        ;; Show progress
        (when (= (mod progress 10) 0)
          (message "Loading decompiled content... %d%%" progress))

        (insert (substring content pos end-pos))

        (if (< end-pos (length content))
            ;; More content to insert - use very short timer
            (run-with-timer 0.001 nil
                            (apply-partially 'jdtls-insert-content-chunk
                                             content target-buffer end-pos chunk-size))
          ;; Done inserting
          (jdtls-finalize-buffer target-buffer))))))

(defun jdtls-finalize-buffer (target-buffer)
  "Finalize buffer setup after content insertion."
  (when (buffer-live-p target-buffer)
    (with-current-buffer target-buffer
      (set-buffer-modified-p nil)
      (goto-char (point-min))
      (java-ts-mode)
      (setq-local semantic-mode nil)

      ;; 延迟启动 eglot 以确保模式设置完成
      (run-with-timer 0.1 nil
                      (apply-partially
                       (lambda (target-buffer)
                         (when (buffer-live-p target-buffer)
                           (with-current-buffer target-buffer
                             (jdtls-setup-eglot-for-decompiled-buffer))))
                       target-buffer))

      (message "JADX decompilation completed!"))))

(defun jdtls-setup-eglot-for-decompiled-buffer ()
  "Set up eglot for decompiled buffer with proper JDT URI."
  ;; 确保我们有原始的 JDT URI
  (when (and buffer-file-name
             (string-match-p "jdt:" buffer-file-name))

    ;; 确保 eglot 管理这个缓冲区
    (unless (eglot-current-server)
      (condition-case err
          (eglot-ensure)
        (error
         (message "Failed to start eglot for decompiled buffer: %s" err))))

    ;; 设置缓冲区为只读，因为这是反编译的代码
    (setq buffer-read-only t)

    (message "Decompiled buffer ready for LSP navigation")))


(defun jdt--virtual-file-p (&optional filename)
  "Return non-nil if FILENAME or current buffer is a JDT virtual file."
  (let ((path (if filename (car filename) buffer-file-name))) ; 处理 &rest
    (and path (string-match-p "jdt:" path))))

(defun jdt--file-writable-p-advice (orig-fun &rest args)
  "Make JDT virtual files appear unwritable."
  (if (and (stringp (car args)) (jdt--virtual-file-p args))
      nil  ; 模拟不可写
    (apply orig-fun args)))
(advice-add 'file-writable-p :around #'jdt--file-writable-p-advice)

(defun jdt-files-p (&rest args)
  "Disable semantic mode and other problematic features for JDT virtual files."
  (let ((check (or (car args) buffer-file-name)))
    (and (stringp check) (string-match-p "jdt:" check))))

(defun disable-semantic-for-jdt-files ()
  "Disable semantic mode and other problematic features for JDT virtual files."
  (when (and buffer-file-name
             (string-match-p "jdt:" buffer-file-name))
    (setq-local semantic-mode nil)
    (setq-local global-semantic-mode nil)
    (setq-local auto-save-default nil)
    (setq-local make-backup-files nil)
    (setq-local create-lockfiles nil)

    ;; 确保反编译后的缓冲区能被 eglot 正确管理
    (when (and (> (buffer-size) 0)  ; 缓冲区不为空
               (not (eglot-current-server))) ; 没有 LSP 服务器
      (run-with-timer 0.5 nil #'jdt--setup-eglot-in-buffer (current-buffer)))))

(defun jdt--setup-eglot-in-buffer (buffer)
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (jdtls-setup-eglot-for-decompiled-buffer))))

;; Auto-decompile empty JDT buffers
(defun auto-decompile-jdt-buffer ()
  "Auto-decompile empty JDT buffers if they match pattern."
  (when (and buffer-file-name
             (string-match-p "jdt:" buffer-file-name)
             (= (buffer-size) 0))
    (jdtls-jadx-decompile-async)))

(add-hook 'find-file-hook #'auto-decompile-jdt-buffer)

(provide 'java-decompile)
;;; java-decompile.el ends here
