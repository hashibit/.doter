;; -*- lexical-binding: t -*-
;;; init-lang-typescript.el --- TypeScript language configuration

;; (use-package typescript-ts-mode
;;   :mode ("\\.ts\\'" "\\.tsx\\'"))
;; Superseded by jtsx below, which registers the same extensions.

;; 纯 .js 走原生 treesit JS mode，避免 JSX parser 误判（如 `a < b > c`）
;; 和 LSP 发错 languageId（"javascriptreact" vs "javascript"）。
(use-package js
  :mode ("\\.js\\'" . js-ts-mode)
  :hook (js-ts-mode . hs-minor-mode)
  :config
  ;; shebang "#!/usr/bin/env node" 优先级高于 auto-mode-alist，默认映射到 js-mode。
  ;; 对 .ts/.tsx 文件改走 jtsx，其余保持 js-ts-mode。
  (add-to-list 'interpreter-mode-alist
    '("node" . (lambda ()
                 (if (and buffer-file-name
                          (string-match "\\.tsx?\\'" buffer-file-name))
                     (jtsx-typescript-mode)
                   (js-ts-mode))))))

(use-package jtsx
  :ensure t
  :mode (("\\.jsx\\'" . jtsx-jsx-mode)
         ("\\.tsx\\'" . jtsx-tsx-mode)
         ("\\.ts\\'" . jtsx-typescript-mode))
  :hook ((jtsx-jsx-mode . hs-minor-mode)
         (jtsx-tsx-mode . hs-minor-mode)
         (jtsx-typescript-mode . hs-minor-mode)
         (jtsx-jsx-mode . (lambda () (rainbow-delimiters-mode -1)))
         (jtsx-tsx-mode . (lambda () (rainbow-delimiters-mode -1))))
  :custom
  ;; Optional customizations
  (js-indent-level 2)
  (typescript-ts-mode-indent-offset 2)
  ;; (jtsx-switch-indent-offset 0)
  ;; (jtsx-indent-statement-block-regarding-standalone-parent nil)
  ;; (jtsx-jsx-element-move-allow-step-out t)
  ;; (jtsx-enable-jsx-electric-closing-element t)
  ;; (jtsx-enable-electric-open-newline-between-jsx-element-tags t)
  ;; (jtsx-enable-jsx-element-tags-auto-sync nil)
  (jtsx-enable-all-syntax-highlighting-features t)
  :config
  (defun jtsx-bind-keys-to-mode-map (mode-map)
    "Bind keys to MODE-MAP."
    (define-key mode-map (kbd "C-c C-j") 'jtsx-jump-jsx-element-tag-dwim)
    (define-key mode-map (kbd "C-c j o") 'jtsx-jump-jsx-opening-tag)
    (define-key mode-map (kbd "C-c j c") 'jtsx-jump-jsx-closing-tag)
    (define-key mode-map (kbd "C-c j r") 'jtsx-rename-jsx-element)
    (define-key mode-map (kbd "C-c <down>") 'jtsx-move-jsx-element-tag-forward)
    (define-key mode-map (kbd "C-c <up>") 'jtsx-move-jsx-element-tag-backward)
    (define-key mode-map (kbd "C-c C-<down>") 'jtsx-move-jsx-element-forward)
    (define-key mode-map (kbd "C-c C-<up>") 'jtsx-move-jsx-element-backward)
    (define-key mode-map (kbd "C-c C-S-<down>") 'jtsx-move-jsx-element-step-in-forward)
    (define-key mode-map (kbd "C-c C-S-<up>") 'jtsx-move-jsx-element-step-in-backward)
    (define-key mode-map (kbd "C-c j w") 'jtsx-wrap-in-jsx-element)
    (define-key mode-map (kbd "C-c j u") 'jtsx-unwrap-jsx)
    (define-key mode-map (kbd "C-c j d n") 'jtsx-delete-jsx-node)
    (define-key mode-map (kbd "C-c j d a") 'jtsx-delete-jsx-attribute)
    (define-key mode-map (kbd "C-c j t") 'jtsx-toggle-jsx-attributes-orientation)
    (define-key mode-map (kbd "C-c j h") 'jtsx-rearrange-jsx-attributes-horizontally)
    (define-key mode-map (kbd "C-c j v") 'jtsx-rearrange-jsx-attributes-vertically))

  (defun jtsx-bind-keys-to-jtsx-jsx-mode-map ()
    "Bind JTSX keys to jsx mode map."
    (jtsx-bind-keys-to-mode-map jtsx-jsx-mode-map))

  (defun jtsx-bind-keys-to-jtsx-tsx-mode-map ()
    "Bind JTSX keys to tsx mode map."
    (jtsx-bind-keys-to-mode-map jtsx-tsx-mode-map))

  (add-hook 'jtsx-jsx-mode-hook 'jtsx-bind-keys-to-jtsx-jsx-mode-map)
  (add-hook 'jtsx-tsx-mode-hook 'jtsx-bind-keys-to-jtsx-tsx-mode-map)

  ;; eglot 通过 major-mode symbol 上的 eglot-language-id 属性确定 languageId。
  ;; jtsx 派生自 ts 内建 mode，但 eglot 不自动识别，需显式声明。
  (put 'jtsx-typescript-mode 'eglot-language-id "typescript")
  (put 'jtsx-tsx-mode        'eglot-language-id "typescriptreact")
  (put 'jtsx-jsx-mode        'eglot-language-id "javascriptreact"))

(provide 'init-lang-typescript)

;;; init-lang-typescript.el ends here
