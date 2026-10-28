;;; -*- lexical-binding: t -*-

(defvar ignored-projectile-projects (list "/opt/homebrew/" "Xcode.app" "node_modules"))

(defun ignored-projectile-project (project-root)
  (seq-some (lambda (candidate) (string-search candidate project-root))
            ignored-projectile-projects))

(use-package projectile
  :ensure t
  :config
  ;; projectile 3.x: entries are gitignore-style patterns (plain name
  ;; matches at any depth, slash anchors at project root), NOT regexps.
  ;; Anchored regexes like "^\\.git$" silently stop matching -- keep this
  ;; list in gitignore style.  /opt/homebrew is handled by
  ;; ignored-projectile-project below instead.
  (setq projectile-globally-ignored-directories
        '("node_modules"
          ".venv"
          ".shadow-cljs"
          "venv"
          ".specstory"
          ".next"
          ".nuxt"
          "dist"
          "build"
          "target"
          "coverage"
          ".nyc_output"
          "public/build"
          "static/build"
          "__pycache__"
          ".emacs.d/.local/autosaves"
          ".emacs.d/.local/auto-save-list"
          ".emacs.d/.local/cache"
          ".emacs.d/.local/backup"
          ".emacs.d/.local/backups"
          ".idea"
          ".vscode"
          ".ensime_cache"
          ".eunit"
          ".git"
          ".hg"
          ".fslckout"
          "_FOSSIL_"
          ".bzr"
          "_darcs"
          ".pijul"
          ".tox"
          ".svn"
          ".stack-work"
          ".ccls-cache"
          ".cache"
          ".clangd"
          ".ccbus"
          ".claude"
          ".understand-anything"))

  (setq-default
   projectile-cache-file (locate-user-emacs-file ".local/projectile.cache")
   projectile-known-projects-file (locate-user-emacs-file ".local/projectile-bookmarks.eld")
   projectile-enable-caching t
   projectile-indexing-method 'native
   projectile-track-known-projects-automatically t
   projectile-ignored-project-function 'ignored-projectile-project)


  (setq projectile-project-root-files
        '("pyproject.toml"     ; Python (uv, poetry, etc.)
          "Cargo.toml"         ; Rust
          "package.json"       ; Node.js/JavaScript
          "go.mod"             ; Go
          "pom.xml"            ; Java Maven
          "build.gradle"       ; Java Gradle
          "composer.json"      ; PHP
          "Gemfile"            ; Ruby
          "mix.exs"            ; Elixir
          "Project.toml"       ; Julia
          "dune-project"       ; OCaml
          "stack.yaml"         ; Haskell Stack
          "cabal.project"))    ; Haskell Cabal

  (setq projectile-project-root-files-bottom-up
        '(".git"
          ".hg"
          ".bzr"
          ".svn"))

  (projectile-mode +1))

(setq projectile-completion-system 'ivy)

(declare-function projectile-acquire-root "projectile")
(declare-function projectile-completing-read "projectile")
(declare-function projectile-project-files "projectile")

(defun my-projectile-find-file ()
  "Find file in current project. If text is selected, use it as initial input."
  (interactive)
  (let ((initial-input (when (region-active-p)
                         (buffer-substring-no-properties (region-beginning) (region-end)))))
    (when (region-active-p)
      (deactivate-mark))
    (if initial-input
        (let* ((project-root (projectile-acquire-root))
               (file (projectile-completing-read "Find file: "
                                                 (projectile-project-files project-root)
                                                 :initial-input initial-input)))
          (when file
            (find-file (expand-file-name file project-root))
            (run-hooks 'projectile-find-file-hook)))
      (projectile-find-file))))

(defun my-projectile-switch-project-find-file ()
  (interactive)
  (let ((projectile-switch-project-action #'projectile-find-file))
    (projectile-switch-project)))

(defun my/return-t (&rest _) t)

(defun my/disable-yornp (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, answering every yes/no prompt with yes."
  (cl-letf (((symbol-function 'yes-or-no-p) #'my/return-t)
            ((symbol-function 'y-or-n-p) #'my/return-t))
    (apply orig-fun args)))


(advice-add 'projectile-compile-project :around #'my/disable-yornp)
(advice-add 'projectile-run-project :around #'my/disable-yornp)



;; Projectile scoped xref
;; https://magnus.therning.org/2023-03-03-per-project-xref-history-in-emacs.html

(defun projectile-param-xref-history (&optional new-value)
  "Return project-local xref history for the current projectile.

Override existing value with NEW-VALUE if it's set."
  (if new-value
      (projectile-param-set-parameter 'xref--history new-value)
    (or (projectile-param-get-parameter 'xref--history)
        (projectile-param-set-parameter 'xref--history (xref--make-xref-history)))))

(defvar projectile-params--store (make-hash-table :test 'equal)
  "The store of project parameters.")

(defun projectile-param-get-parameter (param)
  "Return project parameter PARAM, or nil if unset."
  (let ((key (cons (projectile-project-name) param)))
    (gethash key projectile-params--store nil)))

(defun projectile-param-set-parameter (param value)
  "Set the project parameter PARAM to VALUE."
  (let ((key (cons (projectile-project-name) param)))
    (puthash key value projectile-params--store))
  value)


(with-eval-after-load 'xref
  (setq xref-history-storage #'projectile-param-xref-history))


(provide 'init-projectile)
