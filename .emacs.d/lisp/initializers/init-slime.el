
;;
;; brew install roswell
;;

(use-package slime
  :ensure t
  :defer t
  :init
  (setq inferior-lisp-program "sbcl")
  ;; 在 Lisp 启动时就加载 Quicklisp 的 Swank
  ;;;;; (setq slime-lisp-implementations
  ;;;;;       '((sbcl ("ros" "-L" "sbcl-bin"
  ;;;;;                "-e" "(ql:quickload :swank)"
  ;;;;;                "-e" "(swank:create-server :dont-close t)"
  ;;;;;                "run"))))
  :config
  (slime-setup '(slime-fancy slime-asdf slime-indentation))
  ;; slime 的 minor-mode keymap 在 slime-mode / slime-autodoc-mode 启用时
  ;; 注册到 minor-mode-map-alist 靠前的位置，会遮住 god-local-mode-map，
  ;; 导致 god mode 下 SPC 走 slime-space / slime-autodoc-space 而不是 leader 键。
  ;; 去掉这些绑定：god 开启时 SPC 走 leader，关闭时走 self-insert。
  (dolist (map (list slime-mode-map
                     slime-editing-map
                     (bound-and-true-p slime-autodoc-mode-map)))
    (when map
      (define-key map (kbd "SPC") nil)))
  ;; 兼容一下 xref
  (define-key slime-mode-map [remap xref-find-references] #'slime-who-calls)
  ;; 高亮 who calls 列表项
  (advice-add 'slime-goto-location-position :after
              (lambda (&rest _)
                (when (fboundp 'pulse-momentary-highlight-one-line)
                  (pulse-momentary-highlight-one-line (point)))))
  )

(use-package slime-company
  :after slime
  :bind ((:map slime-repl-mode-map
           ("C-n" . company-select-next)
           ("C-p" . company-select-previous)
           ("M-." . company-show-location)
           ))
  :config
  (setq
    slime-company-completion 'fuzzy
    slime-company-after-completion 'slime-company-just-one-space))


(provide 'init-slime)
