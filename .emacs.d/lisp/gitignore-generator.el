;;; gitignore-generator.el --- Generate .gitignore files -*- lexical-binding: t -*-

;;; Commentary:
;; 自动生成各种项目类型的 .gitignore 文件

;;; Code:

;; =============================================================================
;; .gitignore 模板定义
;; =============================================================================

(defvar my/gitignore-templates
  '((clojure . "# Clojure
target/
.lein-*
.nrepl-port
.cpcache/
.rebel_readline_history
pom.xml
pom.xml.asc
*.jar
*.class

.clj-kondo
.lsp

# Shadow-CLJS
.shadow-cljs/
node_modules/
.nrepl-history

# CIDER
.cider-repl-history
.nrepl-port

# Editor
.idea/
*.iml
.vscode/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
")

     (javascript . "# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build
dist/
build/
.cache/
.parcel-cache/

# Environment
.env
.env.local
.env.*.local

# Editor
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
logs/
")

     (python . "# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
ENV/
env/
.venv

# PyCharm
.idea/

# VS Code
.vscode/

# pytest
.pytest_cache/
.coverage
htmlcov/

# Jupyter
.ipynb_checkpoints

# mypy
.mypy_cache/
.dmypy.json

# Editor
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
")

     (rust . "# Build output
target/

# Editor
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
")

     (go . "# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out

# Go workspace file
go.work

# Vendor
vendor/

# Editor
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
")

     (java . "# Compiled class files
*.class

# Package Files
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties

# Gradle
.gradle/
build/

# IntelliJ IDEA
.idea/
*.iml
*.iws
*.ipr
out/

# Eclipse
.classpath
.project
.settings/
bin/

# Editor
.vscode/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
")

     (emacs . "# Emacs
*~
\\#*\\#
/.emacs.desktop
/.emacs.desktop.lock
*.elc
auto-save-list
tramp
.\\#*

# Org-mode
.org-id-locations
*_archive

# ELPA packages
elpa/

# Backup files
*.bak
*.tmp
*-autoloads.el

# Eshell
eshell/history
eshell/lastdir

# REPL history
.cider-repl-history
.nrepl-history

# Logs
*.log
")

     (web . "# Dependencies
node_modules/
bower_components/

# Build
dist/
build/
*.min.js
*.min.css

# Environment
.env
.env.local

# Editor
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
npm-debug.log*
yarn-debug.log*
"))
  "各种项目类型的 .gitignore 模板")

;; =============================================================================
;; 主要功能函数
;; =============================================================================

(declare-function projectile-project-root "projectile")

(defun my/gitignore--project-root ()
  "当前项目根目录：projectile > project.el > `default-directory'."
  (or (and (fboundp 'projectile-project-root)
           (ignore-errors (projectile-project-root)))
      (when-let* ((project (project-current)))
        (project-root project))
      default-directory))

(defun my/generate-gitignore (&optional project-type)
  "在当前项目根目录生成 .gitignore 文件。
如果 PROJECT-TYPE 为 nil，则提示用户选择项目类型。"
  (interactive)
  (let* ((project-root (my/gitignore--project-root))
          (gitignore-path (expand-file-name ".gitignore" project-root))
          (type (or project-type
                  (intern (completing-read
                            "选择项目类型: "
                            (mapcar #'car my/gitignore-templates)
                            nil t))))
          (template (alist-get type my/gitignore-templates)))

    (if (null template)
      (message "未找到 %s 类型的模板" type)
      (if (file-exists-p gitignore-path)
        (when (yes-or-no-p (format "%s 已存在，是否覆盖？" gitignore-path))
          (my/write-gitignore gitignore-path template))
        (my/write-gitignore gitignore-path template)))))

(defun my/write-gitignore (path content)
  "将内容写入 .gitignore 文件。"
  (with-temp-file path
    (insert content))
  (message "已生成 %s" path)
  (when (yes-or-no-p "是否打开查看？")
    (find-file path)))

(defun my/add-to-gitignore (pattern)
  "添加一个模式到当前项目的 .gitignore 文件。"
  (interactive "s添加到 .gitignore: ")
  (let* ((project-root (my/gitignore--project-root))
          (gitignore-path (expand-file-name ".gitignore" project-root)))

    (if (not (file-exists-p gitignore-path))
      (message "未找到 .gitignore 文件，请先创建")
      (with-current-buffer (find-file-noselect gitignore-path)
        (goto-char (point-max))
        (unless (bolp) (insert "\n"))
        (insert pattern "\n")
        (save-buffer)
        (message "已添加 '%s' 到 %s" pattern gitignore-path)))))

(defun my/append-gitignore-template (type)
  "追加一个模板到现有的 .gitignore 文件。"
  (interactive (list (intern (completing-read
                               "选择要追加的模板: "
                               (mapcar #'car my/gitignore-templates)
                               nil t))))
  (let* ((project-root (my/gitignore--project-root))
          (gitignore-path (expand-file-name ".gitignore" project-root))
          (template (alist-get type my/gitignore-templates)))

    (if (null template)
      (message "未找到 %s 类型的模板" type)
      (if (not (file-exists-p gitignore-path))
        (message "未找到 .gitignore 文件，请先创建")
        (with-current-buffer (find-file-noselect gitignore-path)
          (goto-char (point-max))
          (unless (bolp) (insert "\n"))
          (insert "\n" template)
          (save-buffer)
          (message "已追加 %s 模板到 %s" type gitignore-path))))))

;; =============================================================================
;; 自动检测项目类型
;; =============================================================================

(defun my/detect-project-type ()
  "自动检测当前项目类型。"
  (let ((project-root (my/gitignore--project-root)))
    (cond
      ((or (file-exists-p (expand-file-name "project.clj" project-root))
         (file-exists-p (expand-file-name "deps.edn" project-root))
         (file-exists-p (expand-file-name "shadow-cljs.edn" project-root)))
        'clojure)

      ((or (file-exists-p (expand-file-name "package.json" project-root))
         (file-exists-p (expand-file-name "yarn.lock" project-root)))
        'javascript)

      ((or (file-exists-p (expand-file-name "requirements.txt" project-root))
         (file-exists-p (expand-file-name "setup.py" project-root))
         (file-exists-p (expand-file-name "Pipfile" project-root)))
        'python)

      ((file-exists-p (expand-file-name "Cargo.toml" project-root))
        'rust)

      ((file-exists-p (expand-file-name "go.mod" project-root))
        'go)

      ((or (file-exists-p (expand-file-name "pom.xml" project-root))
         (file-exists-p (expand-file-name "build.gradle" project-root)))
        'java)

      (t nil))))

(defun my/smart-generate-gitignore ()
  "智能生成 .gitignore，自动检测项目类型。"
  (interactive)
  (let ((detected-type (my/detect-project-type)))
    (if detected-type
      (progn
        (message "检测到项目类型: %s" detected-type)
        (my/generate-gitignore detected-type))
      (my/generate-gitignore))))

;; =============================================================================
;; 快捷键绑定建议
;; =============================================================================

;; 取消注释以启用快捷键
;; (global-set-key (kbd "C-c g i") #'my/smart-generate-gitignore)
;; (global-set-key (kbd "C-c g a") #'my/add-to-gitignore)
;; (global-set-key (kbd "C-c g p") #'my/append-gitignore-template)

(provide 'gitignore-generator)

;;; gitignore-generator.el ends here
