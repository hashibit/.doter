;;; -*- lexical-binding: t -*-
;;; Emacs Lisp Mode Hook
(defun my-elisp-mode-hook ()
  ;; Emacs 32 起此变量是 EditorConfig indent_size 的载体：
  ;; 非 nil 会完全绕过 common-lisp-indent-function 的对齐逻辑，
  ;; 强制所有行 = 外层括号列 + offset。所以要注释掉
  ;;;; (setq lisp-indent-offset 2)
  (my-enable-symbol-overlay-highlight))

(add-hook 'emacs-lisp-mode-hook #'my-elisp-mode-hook)
(add-hook 'lisp-mode-hook #'my-elisp-mode-hook)

(use-package lispy
  :hook
  (emacs-lisp-mode . lispy-mode)
  (lisp-mode . lispy-mode)
  :config
  (setcdr lispy-goto-mode-map nil)
  (setcdr lispy-other-mode-map nil)
  (setcdr lispy-mode-map nil)
  (setcdr lispy-mode-map-oleh nil)
  (setcdr lispy-mode-map-base nil)
  (setcdr lispy-mode-map-lispy nil)
  (setcdr lispy-mode-map-evilcp nil)
  (setcdr lispy-mode-map-special nil)
  (setcdr lispy-mode-map-paredit nil)
  (setcdr lispy-mode-map-parinfer nil)
  (setcdr lispy-mode-map-c-digits nil)
  (keymap-set lispy-mode-map "M" #'special-lispy-alt-multiline)
  (keymap-set lispy-mode-map "s-m" #'special-lispy-alt-multiline)
  ;; s-j is taken by the eat popup (bind-key* in my-key-bindings.el).
  (keymap-set lispy-mode-map "M-s-j" #'lispy-down)
  (keymap-set lispy-mode-map "s-k" #'lispy-up))


(use-package elisp-autofmt
  :hook (emacs-lisp-mode . elisp-autofmt-mode)
  :config
  (setq elisp-autofmt-style 'fixed)
  (setq elisp-autofmt-format-quoted nil))


(use-package symbol-overlay
  :hook (emacs-lisp-mode . symbol-overlay-mode)
  :config
  (setq symbol-overlay-idle-time 0.1)
  ;; Face configuration moved to custom-set-faces
  )


(provide 'init-emacs-lispy)
