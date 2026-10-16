;; -*- lexical-binding: t -*-
;;; init-lang-perl.el --- Perl language configuration

(require 'perl-ts-mode)


(use-package perl-mode
  :ensure t
  :config
  (setq cperl-indent-level 4)

  (defun my-install-perl-ts-gramma()
    (interactive)
    (add-to-list 'treesit-language-source-alist
         '(perl . ("https://github.com/tree-sitter-perl/tree-sitter-perl" "release")))
    (add-to-list 'treesit-language-source-alist
         '(pod . ("https://github.com/tree-sitter-perl/tree-sitter-pod" "release")))
    (treesit-install-language-grammar 'perl)
    (treesit-install-language-grammar 'pod))

  (add-to-list 'major-mode-remap-alist '(perl-mode . perl-ts-mode))
)


(provide 'init-lang-perl)

;;; init-lang-perl.el ends here
