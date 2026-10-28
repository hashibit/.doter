;; -*- lexical-binding: t -*-
;;; init-treesit.el --- Tree-sitter configuration

;;; Code:

(use-package treesit
  :demand t
  :custom
  (treesit-font-lock-level 4) ;; skittles highlighting
  :mode (
         ;; ("\\.tsx\\'" . tsx-ts-mode)
         ;; ("\\.js\\'"  . typescript-ts-mode)
         ;; ("\\.mjs\\'" . typescript-ts-mode)
         ;; ("\\.mts\\'" . typescript-ts-mode)
         ;; ("\\.cjs\\'" . typescript-ts-mode)
         ;; ("\\.ts\\'"  . typescript-ts-mode)
         ;; ("\\.jsx\\'" . tsx-ts-mode)
         ("\\.json\\'" .  json-ts-mode)
         ("\\.clj\\'" . clojure-ts-mode)
         ("\\.cljs\\'" . clojure-ts-mode)
         ("\\.cljc\\'" . clojure-ts-mode)
         ("\\.edn\\'" . clojure-ts-mode))
  :init
  (push '(css-mode . css-ts-mode) major-mode-remap-alist)
  (push '(clojure-mode . clojure-ts-mode) major-mode-remap-alist)
  (push '(sh-mode . bash-ts-mode) major-mode-remap-alist)
  (push '(python-mode . python-ts-mode) major-mode-remap-alist)
  (push '(js-json-mode . json-ts-mode) major-mode-remap-alist)
  ;; ;; js ts mode is not working yet.
  ;; (push '(javascript-mode . javascript-ts-mode) major-mode-remap-alist)
  ;; (push '(typescript-mode . typescript-ts-mode) major-mode-remap-alist)
  ;; ;; go-mode does not support treesitter yet.
  ;; (push '(go-mode . go-ts-mode) major-mode-remap-alist)
  (push '(c-mode . c-ts-mode) major-mode-remap-alist)
  (push '(c++-mode . c++-ts-mode) major-mode-remap-alist)
  (push '(cmake-mode . cmake-ts-mode) major-mode-remap-alist)
  (add-to-list 'auto-mode-alist '("\\.h\\'" . c++-ts-mode)) ;; tell h file to c++-ts-mode
  (add-to-list 'auto-mode-alist '("\\.mm\\'" . c++-ts-mode)) ;; tell h file to c++-ts-mode
  (add-to-list 'auto-mode-alist '("\\.ros\\'" . lisp-mode)) ;; tell ros file to emacs lisp mode
  ;; (setq treesit-extra-load-path `( ,(locate-user-emacs-file ".local/tree-sitter-grammars") ))
  ;; (add-to-list 'treesit-language-source-alist
  ;;            '(mermaid "https://github.com/monaqa/tree-sitter-mermaid" "master"))
  :config
  (add-to-list 'treesit-language-source-alist
               '(go "https://github.com/tree-sitter/tree-sitter-go" "v0.19.1")))


;; perf: treesit-auto--build-major-mode-remap-alist is called on every
;; set-auto-mode-0 (every file open) and calls treesit-language-available-p
;; for each language, hitting the filesystem ~20+ times.  Cache it.
;; CAUTION: advises a private treesit-auto function.
(defvar my-treesit-auto--remap-alist-cache nil
  "Cached result of `treesit-auto--build-major-mode-remap-alist'.")

(defun my-treesit-auto--cached-remap-alist (orig-fun &rest args)
  (or my-treesit-auto--remap-alist-cache
      (setq my-treesit-auto--remap-alist-cache (apply orig-fun args))))

(defun my-treesit-auto--bust-remap-alist-cache (&rest _)
  (setq my-treesit-auto--remap-alist-cache nil))

;; invoke M-x treesit-auto-install-all to install treesit libs to ~/.emacs.d/tree-sitter/
;; (Emacs 31 has `treesit-enabled-modes', but no auto grammar install; keep treesit-auto)
(use-package treesit-auto
  :config
  ;; markdown-ts-mode applies bold face to all paragraph text (upstream bug)
  (setq treesit-auto-langs (remove 'markdown treesit-auto-langs))

  (advice-add 'treesit-auto--build-major-mode-remap-alist :around
              #'my-treesit-auto--cached-remap-alist)
  ;; bust cache after installing new grammars
  (advice-add 'treesit-auto-install-all :after #'my-treesit-auto--bust-remap-alist-cache)

  (global-treesit-auto-mode))

(provide 'init-treesit)

;;; init-treesit.el ends here
