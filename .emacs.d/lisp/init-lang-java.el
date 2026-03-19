;; init-lang-java.el --- Java Configurations	-*- lexical-binding: t -*-

;; Author: Zsxh Chen <bnbvbchen@gmail.com>
;; URL: https://github.com/zsxh/emacs.d

;;; Commentary:
;;
;;  Java Configurations
;;

;;; Code:

;; Java development environment paths
(defvar java-local-dir (expand-file-name "~/.emacs.d/.local"))
(defvar java-dev-dir (file-name-concat java-local-dir "java"))
(defvar java-lombok-dir (file-name-concat java-dev-dir "lombok"))
(defvar java-test-runner-dir (file-name-concat java-dev-dir "test-runner"))

;; JDT Language Server paths
(defvar jdt-language-server-dir (file-name-concat java-local-dir "jdt-language-server-latest"))
(defvar jdt-language-server-workspaces (file-name-concat java-local-dir "jdt-language-server-workspaces"))

(defvar jdt-language-server-config-dir
  (file-name-concat jdt-language-server-dir
    (cond
      ((eq system-type 'darwin)
       (if (string-match-p "arm64\\|aarch64" system-configuration)
           "config_mac_arm"
         "config_mac"))
      ((eq system-type 'gnu/linux) "config_linux")
      ((eq system-type 'windows-nt) "config_win")
      (t "config_linux"))))

;; Java development JAR files
(defvar java-lombok-jar (file-name-concat java-lombok-dir "lombok.jar"))
(defvar java-junit-platform-console-standalone-jar (file-name-concat java-test-runner-dir "junit-platform-console-standalone.jar"))

;; Java formatter configuration
(defvar java-google-style-formatter (file-name-concat java-local-dir "eclipse-java-google-style.xml"))

;; Java runtime configuration
(defvar java-runtime-path
  (or (getenv "JAVA_HOME")
    (cond
      ((eq system-type 'darwin)
        (or (and (file-exists-p "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")
              "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")
          (and (file-exists-p "/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")
            "/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")))
      ((eq system-type 'gnu/linux)
        (or (and (file-exists-p "/usr/lib/jvm/java-21-openjdk-amd64")
              "/usr/lib/jvm/java-21-openjdk-amd64")
          (and (file-exists-p "/usr/lib/jvm/java-21-openjdk")
            "/usr/lib/jvm/java-21-openjdk")))))
  "Java runtime path for JDT Language Server.")


;; JUnit 版本
(defvar java-junit-version "1.10.1"
  "JUnit Platform Console Standalone version to download.")

;; 下载 URL
(defvar java-lombok-url "https://projectlombok.org/downloads/lombok.jar")
(defvar java-junit-url-template "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/%s/junit-platform-console-standalone-%s.jar")
(defvar jdt-language-server-url "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz")

;;
;; 下载方法和清理方法
;;
(defun java-setup-create-directories ()
  "创建 Java 开发所需的所有目录。"
  (interactive)
  (dolist (dir (list java-lombok-dir
                 java-test-runner-dir
                 jdt-language-server-dir
                 jdt-language-server-workspaces))
    (unless (file-exists-p dir)
      (make-directory dir t)
      (message "Created directory: %s" dir))))

(defun java-setup-download-file (url destination)
  "从 URL 下载文件到 DESTINATION。"
  (let ((download-buffer (url-retrieve-synchronously url t)))
    (when download-buffer
      (with-current-buffer download-buffer
        (goto-char (point-min))
        ;; 跳过 HTTP 头
        (re-search-forward "^$" nil 'move)
        (forward-char)
        (delete-region (point-min) (point))
        ;; 写入文件
        (let ((coding-system-for-write 'binary))
          (write-region (point-min) (point-max) destination))
        (kill-buffer))
      (message "Downloaded: %s" destination)
      t)))

(defun java-setup-download-lombok ()
  "下载 Lombok JAR 文件。"
  (interactive)
  (java-setup-create-directories)
  (if (file-exists-p java-lombok-jar)
    (message "Lombok already exists: %s" java-lombok-jar)
    (message "Downloading Lombok...")
    (java-setup-download-file java-lombok-url java-lombok-jar)))

(defun java-setup-download-junit ()
  "下载 JUnit Platform Console Standalone JAR 文件。"
  (interactive)
  (java-setup-create-directories)
  (if (file-exists-p java-junit-platform-console-standalone-jar)
    (message "JUnit already exists: %s" java-junit-platform-console-standalone-jar)
    (message "Downloading JUnit %s..." java-junit-version)
    (let ((url (format java-junit-url-template java-junit-version java-junit-version)))
      (java-setup-download-file url java-junit-platform-console-standalone-jar))))

(defun java-setup-download-jdt-ls ()
  "下载并解压 JDT Language Server。"
  (interactive)
  (java-setup-create-directories)
  (let ((tar-file (file-name-concat jdt-language-server-dir "jdt-language-server-latest.tar.gz")))
    (if (file-exists-p (file-name-concat jdt-language-server-dir "plugins"))
      (message "JDT Language Server already exists: %s" jdt-language-server-dir)
      (message "Downloading JDT Language Server...")
      (when (java-setup-download-file jdt-language-server-url tar-file)
        (message "Extracting JDT Language Server...")
        (let ((default-directory jdt-language-server-dir))
          (shell-command (format "tar -xzf %s" (shell-quote-argument tar-file))))
        (delete-file tar-file)
        (message "JDT Language Server installed successfully!")))))

(defun java-setup-download-all ()
  "下载所有 Java 开发所需的文件。"
  (interactive)
  (java-setup-download-lombok)
  (java-setup-download-junit)
  (java-setup-download-jdt-ls)
  (message "Java setup complete!"))

(defun java-setup-clean ()
  "清理所有下载的 Java 开发文件（保留目录结构）。"
  (interactive)
  (when (yes-or-no-p "Remove downloaded Java setup files (Lombok, JUnit, JDT LS)? ")
    (when (file-exists-p java-lombok-jar)
      (delete-file java-lombok-jar)
      (message "Removed: %s" java-lombok-jar))
    (when (file-exists-p java-junit-platform-console-standalone-jar)
      (delete-file java-junit-platform-console-standalone-jar)
      (message "Removed: %s" java-junit-platform-console-standalone-jar))
    (when (file-exists-p jdt-language-server-dir)
      (delete-directory jdt-language-server-dir t)
      (message "Removed: %s" jdt-language-server-dir))
    (message "Java setup files cleaned!")))

(defun java-setup-check ()
  "检查 Java 开发环境是否已正确设置。"
  (interactive)
  (let ((files (list (cons "Lombok" java-lombok-jar)
                 (cons "JUnit" java-junit-platform-console-standalone-jar)
                 (cons "JDT LS plugins" (file-name-concat jdt-language-server-dir "plugins")))))
    (message "Java Setup Status:")
    (dolist (file files)
      (message "  %s: %s"
        (car file)
        (if (file-exists-p (cdr file))
          "✓ Installed"
          "✗ Missing")))))



;; Helper function for jdtls contact
(defun eglot-jdtls-contact (interactive)
  `(,(file-name-concat jdt-language-server-dir "bin" "jdtls")
     ;; 指定 Java 运行时路径
     "--java-executable" ,(file-name-concat java-runtime-path "bin" "java")
     ;; Use macOS ARM config for M1 Mac
     "-configuration" ,jdt-language-server-config-dir
     "-data" ,(file-name-concat
                jdt-language-server-workspaces
                (file-name-base (directory-file-name (project-root (eglot--current-project)))))
     ;; Lombok support for Java annotations
     ,(concat "--jvm-arg=-javaagent:" java-lombok-jar)
     ;; JVM memory and GC settings
     "--jvm-arg=-Xmx2G"
     "--jvm-arg=-XX:+UseG1GC"
     "--jvm-arg=-XX:+UseStringDeduplication"))

(defun eglot-clear-project-jdtls-data()
  (interactive)
  (delete-directory
    (file-name-concat
      jdt-language-server-workspaces
      (file-name-base (directory-file-name (project-root (eglot--current-project)))))
    t)
  (eglot-shutdown (eglot-current-server))
  (eglot-ensure)
  )

;; Configure java-ts-mode (Tree-sitter Java mode)
(use-package java-ts-mode
  :when (and (treesit-available-p) (treesit-language-available-p 'java))
  :mode "\\.java\\'"
  :config
  ;; Ensure .java files use java-ts-mode instead of java-mode
  (add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode))

  ;; Configure eglot to use jdtls for java-ts-mode
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(java-ts-mode . eglot-jdtls-contact)))

  ;; Set up keybindings for java-ts-mode
  (+funcs/major-mode-leader-keys
    java-ts-mode-map
    "r" '(nil :which-key "run")
    "rt" '(eglot-java-run-test :which-key "run-test-at-point")
    "rm" '(eglot-java-run-main :which-key "run-main"))

  :hook (java-ts-mode . eglot-ensure))

;; Helper function for Java LSP initialization options
(defun java-eglot-initialization-options ()
  "JDT LS initialization options for java-ts-mode."
  `(:settings
     (:java
       (:configuration
         ;; Update Java runtime paths for macOS with Homebrew OpenJDK
         (:runtime [(:name "JavaSE-21" :path ,java-runtime-path :default t)])
         :format (:settings (:url ,java-google-style-formatter
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

;; 确保 Eglot 已经加载
(with-eval-after-load 'eglot
  ;; 方法特化 - 确保 Eglot 已经加载
  (cl-defmethod eglot-initialization-options
    ((server eglot-lsp-server)          ; 参数类型约束：server 必须是 eglot-lsp-server 类型
      &context                           ; 开始上下文约束
      (major-mode java-ts-mode))         ; 上下文约束：当前 major-mode 必须是 java-ts-mode
    (java-eglot-initialization-options)))

;; Eglot Java functions (simplified from eglot-java package)
(defun eglot-java--class-fqcn (&optional main-p)
  "Return the fully qualified name of a given class."
  (let* ((document-symbols (eglot-java--document-symbols))
          (package-name (eglot-java--symbol-value document-symbols "Package"))
          (class-name (eglot-java--symbol-value document-symbols "Class"))
          (method-name (unless main-p (eglot-java--method-name document-symbols class-name)))
          (package-suffix (if (string= "" package-name)
                            package-name
                            "."))
          (cls (format "%s%s%s" package-name package-suffix class-name)))

    (if method-name
      (format "%s#%s" cls method-name)
      cls)))

(defun eglot-java--symbol-value (symbols symbol-type)
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

(defun eglot-java--method-name (symbols class-name)
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

(defun eglot-java--document-symbols ()
  "Fetch the document symbols/tokens."
  (jsonrpc-request
    (eglot--current-server-or-lose)
    :textDocument/documentSymbol
    (list :textDocument (list :uri (eglot--path-to-uri (buffer-file-name))))))

(defun eglot-java--project-classpath (filename scope)
  "Return the classpath for a given FILENAME and SCOPE."
  (plist-get (eglot-execute-command (eglot--current-server-or-lose)
               "java.project.getClasspaths"
               (vector (eglot--path-to-uri filename)
                 (json-encode `(( "scope" . ,scope)))))
    :classpaths))

(defun eglot-java--file--test-p (file-path)
  "Tell if a file locate at FILE-PATH is a test class."
  (eglot-execute-command
    (eglot--current-server-or-lose)
    "java.project.isTestFile"
    (vector (eglot--path-to-uri file-path ))))

(defun eglot-java-run-test ()
  "Run a test class."
  (interactive)
  (let* ((fqcn                 (eglot-java--class-fqcn))
          (cp                   (eglot-java--project-classpath (buffer-file-name) "test"))
          (current-file-is-test (not (equal ':json-false (eglot-java--file--test-p (buffer-file-name))))))

    (unless (file-exists-p java-junit-platform-console-standalone-jar)
      (user-error "%s doest not exit" java-junit-platform-console-standalone-jar))

    (if current-file-is-test
      (compile
        (concat "java -jar "
          java-junit-platform-console-standalone-jar
          (if (string-match-p "#" fqcn) " -m " " -c ")
          fqcn
          " -class-path "
          (mapconcat #'identity cp path-separator)
          " ")
        t)
      (user-error "No test found in current file! Is the file saved?" ))))

(defun eglot-java-run-main ()
  "Run a main class."
  (interactive)
  (let* ((fqcn (eglot-java--class-fqcn t))
          (cp   (eglot-java--project-classpath (buffer-file-name) "runtime")))
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
  :mode "\\.java\\'"
  :after eglot
  :config
  (jarchive-mode 1))

(provide 'init-lang-java)

;;; init-lang-java.el ends here
