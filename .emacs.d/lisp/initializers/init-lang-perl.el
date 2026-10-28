;; -*- lexical-binding: t -*-
;;; init-lang-perl.el --- Perl language configuration

;;; Code:

(require 'perl-ts-mode)

(defun my-install-perl-ts-grammar ()
  "Install the tree-sitter grammars for Perl and POD."
  (interactive)
  (add-to-list 'treesit-language-source-alist
               '(perl . ("https://github.com/tree-sitter-perl/tree-sitter-perl" "release")))
  (add-to-list 'treesit-language-source-alist
               '(pod . ("https://github.com/tree-sitter-perl/tree-sitter-pod" "release")))
  (treesit-install-language-grammar 'perl)
  (treesit-install-language-grammar 'pod))


(use-package perl-mode
  :ensure t
  :config
  (setq cperl-indent-level 4)
  (add-to-list 'major-mode-remap-alist '(perl-mode . perl-ts-mode)))

;; Old name (with the typo), so M-x still finds it.
(define-obsolete-function-alias 'my-install-perl-ts-gramma #'my-install-perl-ts-grammar "2026-10-27")


(provide 'init-lang-perl)

;;; init-lang-perl.el ends here
