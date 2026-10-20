;;; -*- lexical-binding: t -*-

;;
;; brew install roswell
;;

(defun my-slime-pulse-line (&rest _)
  (pulse-momentary-highlight-one-line (point)))

;; slime-autodoc 只给 eldoc 提供参数列表，没有 docstring，
;; 所以 eldoc-box (my-toggle-eldoc-box-help-at-point) 看不到 CL 函数文档。
;; 这里再加一个异步的 docstring 来源，:echo skip 让 echo area 仍只显示参数列表。
(defun my-slime-eldoc-docstring (callback &rest _)
  (when-let* (((slime-connected-p))
              (sym (slime-symbol-at-point)))
    (slime-eval-async `(swank:documentation-symbol ,sym)
      (lambda (doc) (funcall callback doc :echo 'skip)))
    t))

(defun my-slime-eldoc-setup ()
  (add-hook 'eldoc-documentation-functions #'my-slime-eldoc-docstring 90 t)
  (setq-local eldoc-documentation-strategy #'eldoc-documentation-compose))

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
      (keymap-set map "SPC" nil)))
  ;; 兼容一下 xref
  (keymap-set slime-mode-map "<remap> <xref-find-references>" #'slime-who-calls)
  ;; 高亮 who calls 列表项
  (advice-add 'slime-goto-location-position :after #'my-slime-pulse-line)
  (add-hook 'slime-mode-hook #'my-slime-eldoc-setup)
  )

;; 使用 quicklisp 安装的本地 HyperSpec
(load "~/.quicklisp/clhs-use-local.el" 'noerror)

;; C-c C-d h 打开的本地 HyperSpec 用 eww 显示，其他链接仍走默认浏览器
(with-eval-after-load 'browse-url
  (add-to-list 'browse-url-handlers
    '("\\`file://.*/HyperSpec/" . eww-browse-url)))

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
