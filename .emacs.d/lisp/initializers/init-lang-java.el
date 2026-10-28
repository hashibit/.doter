;; init-lang-java.el --- Java Configurations	-*- lexical-binding: t -*-

;; Author: Zsxh Chen <bnbvbchen@gmail.com>
;; URL: https://github.com/zsxh/emacs.d

;;; Commentary:
;;
;;  Java Configurations
;;

;;; Code:

(require 'custom-util-funcs)

;; Java development environment paths
(defvar my-java-local-dir (locate-user-emacs-file ".local"))
(defvar my-java-dev-dir (file-name-concat my-java-local-dir "java"))
(defvar my-java-lombok-dir (file-name-concat my-java-dev-dir "lombok"))
(defvar my-java-test-runner-dir (file-name-concat my-java-dev-dir "test-runner"))

;; JDT Language Server paths
(defvar my-jdt-language-server-dir (file-name-concat my-java-local-dir "jdt-language-server-latest"))
(defvar my-jdt-language-server-workspaces (file-name-concat my-java-local-dir "jdt-language-server-workspaces"))

(defvar my-jdt-language-server-config-dir
  (file-name-concat my-jdt-language-server-dir
                    (cond
                     ((eq system-type 'darwin)
                      (if (string-match-p "arm64\\|aarch64" system-configuration)
                          "config_mac_arm"
                        "config_mac"))
                     ((eq system-type 'gnu/linux) "config_linux")
                     ((eq system-type 'windows-nt) "config_win")
                     (t "config_linux"))))

;; Java development JAR files
(defvar my-java-lombok-jar (file-name-concat my-java-lombok-dir "lombok.jar"))
(defvar my-java-junit-platform-console-standalone-jar (file-name-concat my-java-test-runner-dir "junit-platform-console-standalone.jar"))

;; Java formatter configuration
(defvar my-java-google-style-formatter (file-name-concat my-java-local-dir "eclipse-java-google-style.xml"))

;; Java runtime configuration
(defun my-java--env-java-home ()
  "Return $JAVA_HOME when it is set and non-empty."
  (let ((home (getenv "JAVA_HOME")))
    (unless (string-empty-p (or home ""))
      home)))

(defvar my-java-runtime-path
  (or (my-java--env-java-home)
      (cond
       ((eq system-type 'darwin)
        (or (and (file-exists-p "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")
                 "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")
            (and (file-exists-p "/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")
                 "/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")
            (car (ignore-errors (process-lines "/usr/libexec/java_home" "-v" "21")))))
       ((eq system-type 'gnu/linux)
        (or (and (file-exists-p "/usr/lib/jvm/java-21-openjdk-amd64")
                 "/usr/lib/jvm/java-21-openjdk-amd64")
            (and (file-exists-p "/usr/lib/jvm/java-21-openjdk")
                 "/usr/lib/jvm/java-21-openjdk")))))
  "Java runtime path for JDT Language Server.")


;; JUnit 版本
(defvar my-java-junit-version "1.10.1"
  "JUnit Platform Console Standalone version to download.")

;; 下载 URL
(defvar my-java-lombok-url "https://projectlombok.org/downloads/lombok.jar")
(defvar my-java-junit-url-template "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/%s/junit-platform-console-standalone-%s.jar")
(defvar my-jdt-language-server-url "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz")

;;
;; 下载方法和清理方法
;;
(defun my-java-setup-create-directories ()
  "创建 Java 开发所需的所有目录。"
  (interactive)
  (dolist (dir (list my-java-lombok-dir
                     my-java-test-runner-dir
                     my-jdt-language-server-dir
                     my-jdt-language-server-workspaces))
    (unless (file-exists-p dir)
      (make-directory dir t)
      (message "Created directory: %s" dir))))

(defvar url-http-response-status)

(defun my-java-setup-download-file (url destination)
  "从 URL 下载文件到 DESTINATION。成功返回 t。"
  (let ((download-buffer (url-retrieve-synchronously url t)))
    (when download-buffer
      (unwind-protect
          (with-current-buffer download-buffer
            (let ((status (bound-and-true-p url-http-response-status)))
              (if (not (and (integerp status) (<= 200 status 299)))
                  (progn
                    (message "Download failed (HTTP %s): %s" status url)
                    nil)
                (goto-char (point-min))
                ;; 跳过 HTTP 头
                (re-search-forward "^$" nil 'move)
                (forward-char)
                (delete-region (point-min) (point))
                ;; 写入文件
                (let ((coding-system-for-write 'binary))
                  (write-region (point-min) (point-max) destination))
                (message "Downloaded: %s" destination)
                t)))
        (kill-buffer download-buffer)))))

(defun my-java-setup-download-lombok ()
  "下载 Lombok JAR 文件。"
  (interactive)
  (my-java-setup-create-directories)
  (if (file-exists-p my-java-lombok-jar)
      (message "Lombok already exists: %s" my-java-lombok-jar)
    (message "Downloading Lombok...")
    (my-java-setup-download-file my-java-lombok-url my-java-lombok-jar)))

(defun my-java-setup-download-junit ()
  "下载 JUnit Platform Console Standalone JAR 文件。"
  (interactive)
  (my-java-setup-create-directories)
  (if (file-exists-p my-java-junit-platform-console-standalone-jar)
      (message "JUnit already exists: %s" my-java-junit-platform-console-standalone-jar)
    (message "Downloading JUnit %s..." my-java-junit-version)
    (let ((url (format my-java-junit-url-template my-java-junit-version my-java-junit-version)))
      (my-java-setup-download-file url my-java-junit-platform-console-standalone-jar))))

(defun my-java-setup-download-jdt-ls ()
  "下载并解压 JDT Language Server。"
  (interactive)
  (my-java-setup-create-directories)
  (let ((tar-file (file-name-concat my-jdt-language-server-dir "jdt-language-server-latest.tar.gz")))
    (if (file-exists-p (file-name-concat my-jdt-language-server-dir "plugins"))
        (message "JDT Language Server already exists: %s" my-jdt-language-server-dir)
      (message "Downloading JDT Language Server...")
      (when (my-java-setup-download-file my-jdt-language-server-url tar-file)
        (message "Extracting JDT Language Server...")
        (let* ((default-directory my-jdt-language-server-dir)
               (exit-code (call-process "tar" nil nil nil "-xzf" (expand-file-name tar-file))))
          (delete-file tar-file)
          (if (eq exit-code 0)
              (message "JDT Language Server installed successfully!")
            (message "Failed to extract JDT Language Server (tar exit %s)" exit-code)))))))

(defun my-java-setup-download-all ()
  "下载所有 Java 开发所需的文件。"
  (interactive)
  (my-java-setup-download-lombok)
  (my-java-setup-download-junit)
  (my-java-setup-download-jdt-ls)
  (message "Java setup complete!"))

(defun my-java-setup-clean ()
  "清理所有下载的 Java 开发文件（保留目录结构）。"
  (interactive)
  (when (yes-or-no-p "Remove downloaded Java setup files (Lombok, JUnit, JDT LS)? ")
    (when (file-exists-p my-java-lombok-jar)
      (delete-file my-java-lombok-jar)
      (message "Removed: %s" my-java-lombok-jar))
    (when (file-exists-p my-java-junit-platform-console-standalone-jar)
      (delete-file my-java-junit-platform-console-standalone-jar)
      (message "Removed: %s" my-java-junit-platform-console-standalone-jar))
    (when (file-exists-p my-jdt-language-server-dir)
      (delete-directory my-jdt-language-server-dir t)
      (message "Removed: %s" my-jdt-language-server-dir))
    (message "Java setup files cleaned!")))

(defun my-java-setup-check ()
  "检查 Java 开发环境是否已正确设置。"
  (interactive)
  (let ((files (list (cons "Lombok" my-java-lombok-jar)
                     (cons "JUnit" my-java-junit-platform-console-standalone-jar)
                     (cons "JDT LS plugins" (file-name-concat my-jdt-language-server-dir "plugins")))))
    (message "Java Setup Status:")
    (dolist (file files)
      (message "  %s: %s"
               (car file)
               (if (file-exists-p (cdr file))
                   "✓ Installed"
                 "✗ Missing")))))



(defvar eglot-lsp-context)

(defun my-java--project-name ()
  "Return the current project's directory name, for the jdtls -data dir."
  (let ((project (let ((eglot-lsp-context t))
                   (or (project-current)
                       `(transient . ,(expand-file-name default-directory))))))
    (file-name-base (directory-file-name (project-root project)))))

;; Helper function for jdtls contact
(defun my-eglot-jdtls-contact (_interactive)
  `(,(file-name-concat my-jdt-language-server-dir "bin" "jdtls")
    ;; 指定 Java 运行时路径
    "--java-executable" ,(file-name-concat my-java-runtime-path "bin" "java")
    ;; Use macOS ARM config for M1 Mac
    "-configuration" ,my-jdt-language-server-config-dir
    "-data" ,(file-name-concat my-jdt-language-server-workspaces (my-java--project-name))
    ;; Lombok support for Java annotations
    ,(concat "--jvm-arg=-javaagent:" my-java-lombok-jar)
    ;; JVM memory and GC settings
    "--jvm-arg=-Xmx2G"
    "--jvm-arg=-XX:+UseG1GC"
    "--jvm-arg=-XX:+UseStringDeduplication"
    :initializationOptions ,(my-java-eglot-initialization-options)))

(defun my-eglot-clear-project-jdtls-data()
  "Delete the jdtls data of this project and restart eglot."
  (interactive)
  (delete-directory
   (file-name-concat my-jdt-language-server-workspaces (my-java--project-name))
   t)
  (eglot-shutdown (eglot-current-server))
  (eglot-ensure))

;; Configure java-ts-mode (Tree-sitter Java mode)
(defvar eglot-server-programs)
(declare-function jsonrpc-request "jsonrpc")
(use-package java-ts-mode
  :when (and (treesit-available-p) (treesit-language-available-p 'java))
  :mode "\\.java\\'"
  :config
  ;; Ensure .java files use java-ts-mode instead of java-mode
  (add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode))

  ;; Configure eglot to use jdtls for java-ts-mode
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(java-ts-mode . my-eglot-jdtls-contact)))

  ;; Set up keybindings for java-ts-mode
  (+funcs/major-mode-leader-keys
   java-ts-mode-map
   "r" '(nil :which-key "run")
   "rt" '(my-eglot-java-run-test :which-key "run-test-at-point")
   "rm" '(my-eglot-java-run-main :which-key "run-main"))

  :hook (java-ts-mode . eglot-ensure))

;; Helper function for Java LSP initialization options
(defun my-java-eglot-initialization-options ()
  "JDT LS initialization options for java-ts-mode."
  `(:settings
    (:java
     (:configuration
      ;; Update Java runtime paths for macOS with Homebrew OpenJDK
      (:runtime [(:name "JavaSE-21" :path ,my-java-runtime-path :default t)])
      :format (:settings (:url ,my-java-google-style-formatter
                               :profile "GoogleStyle"))
      :autobuild (:enabled t)
      ;; JDT LS 内置反编译器，无需额外配置
      :contentProvider (:preferred "fernflower"))
     :completion
     (:guessMethodArguments t
                            :overwrite t
                            :enabled t
                            :favoriteStaticMembers ["org.junit.Assert.*"
                                                    "org.junit.Assume.*"
                                                    "org.junit.jupiter.api.Assertions.*"
                                                    "org.junit.jupiter.api.Assumptions.*"
                                                    "org.junit.jupiter.api.DynamicContainer.*"
                                                    "org.junit.jupiter.api.DynamicTest.*"
                                                    "org.mockito.Mockito.*"
                                                    "org.mockito.ArgumentMatchers.*"
                                                    "org.mockito.Answers.*"]))
    ;; support non standard LSP `java/classFileContents', `Location' items that have a `jdt://...' uri
    :extendedClientCapabilities (:classFileContentsSupport t)))

;; initializationOptions 通过 my-eglot-jdtls-contact 返回的 :initializationOptions 传给 jdtls

;; Eglot Java functions (simplified from eglot-java package)
(declare-function eglot-current-server "eglot")
(declare-function eglot-path-to-uri "eglot")
(declare-function eglot-execute-command "eglot")
(declare-function eglot-shutdown "eglot")
(defvar eglot--symbol-kind-names)               ; eglot 内部常量，无公开替代

(defun my-eglot-java--server ()
  "Return the current Eglot server or signal an error."
  (or (eglot-current-server)
      (user-error "No Eglot server for this buffer")))

(defun my-eglot-java--class-fqcn (&optional main-p)
  "Return the fully qualified name of a given class."
  (let* ((document-symbols (my-eglot-java--document-symbols))
         (package-name (my-eglot-java--symbol-value document-symbols "Package"))
         (class-name (my-eglot-java--symbol-value document-symbols "Class"))
         (method-name (unless main-p (my-eglot-java--method-name document-symbols class-name)))
         (package-suffix (if (string= "" package-name)
                             package-name
                           "."))
         (cls (format "%s%s%s" package-name package-suffix class-name)))

    (if method-name
        (format "%s#%s" cls method-name)
      cls)))

(defun my-eglot-java--symbol-value (symbols symbol-type)
  "Extract the symbol value for a given SYMBOL-TYPE from a symbol table SYMBOLS."
  (let ((symbol-details (cl-find-if
                         (lambda (elem)
                           (let* ((elem-kind (plist-get elem :kind))
                                  (elem-type (cdr (assoc elem-kind eglot--symbol-kind-names))))
                             (string= elem-type symbol-type)))
                         symbols)))
    (if symbol-details
        (plist-get symbol-details :name)
      "")))

(defun my-eglot-java--method-name (symbols class-name)
  (let* ((class-symbol (cl-find-if
                        (lambda (elem)
                          (string= (plist-get elem :name) class-name))
                        symbols))
         (method-symbol (cl-find-if
                         (lambda (elem)
                           (if-let* ((elem-kind (plist-get elem :kind))
                                     (elem-type (cdr (assoc elem-kind eglot--symbol-kind-names)))
                                     (method? (string= elem-type "Method"))
                                     (range (plist-get elem :range))
                                     (start (plist-get range :start))
                                     (end (plist-get range :end))
                                     (start-pos (+funcs/pos-at-line-col (plist-get start :line) (plist-get start :character)))
                                     (end-pos (+funcs/pos-at-line-col (plist-get end :line) (plist-get end :character))))
                               (<= start-pos (point) end-pos)))
                         (plist-get class-symbol :children))))
    (when method-symbol
      (let* ((range (plist-get method-symbol :selectionRange))
             (start (plist-get range :start))
             (end (plist-get range :end))
             (start-pos (+funcs/pos-at-line-col (plist-get start :line) (plist-get start :character)))
             (end-pos (+funcs/pos-at-line-col (plist-get end :line) (plist-get end :character))))
        (buffer-substring-no-properties start-pos end-pos)))))

(defun my-eglot-java--document-symbols ()
  "Fetch the document symbols/tokens."
  (jsonrpc-request
   (my-eglot-java--server)
   :textDocument/documentSymbol
   (list :textDocument (list :uri (eglot-path-to-uri (buffer-file-name))))))

(defun my-eglot-java--project-classpath (filename scope)
  "Return the classpath for a given FILENAME and SCOPE."
  (plist-get (eglot-execute (my-eglot-java--server)
                            (list :command "java.project.getClasspaths"
                                  :arguments (vector (eglot-path-to-uri filename)
                                                     (json-encode `(( "scope" . ,scope))))))
             :classpaths))

(defun my-eglot-java--file--test-p (file-path)
  "Tell if a file locate at FILE-PATH is a test class."
  (eglot-execute
   (my-eglot-java--server)
   (list :command "java.project.isTestFile"
         :arguments (vector (eglot-path-to-uri file-path)))))

(defun my-eglot-java-run-test ()
  "Run a test class."
  (interactive)
  (let* ((fqcn                 (my-eglot-java--class-fqcn))
         (cp                   (my-eglot-java--project-classpath (buffer-file-name) "test"))
         (current-file-is-test (not (equal ':json-false (my-eglot-java--file--test-p (buffer-file-name))))))

    (unless (file-exists-p my-java-junit-platform-console-standalone-jar)
      (user-error "%s doest not exit" my-java-junit-platform-console-standalone-jar))

    (if current-file-is-test
        (compile
         (concat "java -jar "
                 my-java-junit-platform-console-standalone-jar
                 (if (string-match-p "#" fqcn) " -m " " -c ")
                 fqcn
                 " -class-path "
                 (mapconcat #'identity cp path-separator)
                 " ")
         t)
      (user-error "No test found in current file! Is the file saved?" ))))

(defun my-eglot-java-run-main ()
  "Run a main class."
  (interactive)
  (let* ((fqcn (my-eglot-java--class-fqcn t))
         (cp   (my-eglot-java--project-classpath (buffer-file-name) "runtime")))
    (if fqcn
        (compile
         (concat "java -cp "
                 (mapconcat #'identity cp path-separator)
                 " "
                 fqcn)
         t)
      (user-error "No main method found in this file! Is the file saved?!"))))

(use-package jarchive
  :ensure t
  :after eglot
  :config
  (jarchive-mode 1))

;; Old names, so M-x with the old name still works.
(define-obsolete-function-alias 'eglot-clear-project-jdtls-data #'my-eglot-clear-project-jdtls-data "2026-10-27")
(define-obsolete-function-alias 'eglot-java-run-main #'my-eglot-java-run-main "2026-10-27")
(define-obsolete-function-alias 'eglot-java-run-test #'my-eglot-java-run-test "2026-10-27")
(define-obsolete-function-alias 'java-setup-check #'my-java-setup-check "2026-10-27")
(define-obsolete-function-alias 'java-setup-clean #'my-java-setup-clean "2026-10-27")
(define-obsolete-function-alias 'java-setup-create-directories #'my-java-setup-create-directories "2026-10-27")
(define-obsolete-function-alias 'java-setup-download-all #'my-java-setup-download-all "2026-10-27")
(define-obsolete-function-alias 'java-setup-download-jdt-ls #'my-java-setup-download-jdt-ls "2026-10-27")
(define-obsolete-function-alias 'java-setup-download-junit #'my-java-setup-download-junit "2026-10-27")
(define-obsolete-function-alias 'java-setup-download-lombok #'my-java-setup-download-lombok "2026-10-27")

(provide 'init-lang-java)

;;; init-lang-java.el ends here
