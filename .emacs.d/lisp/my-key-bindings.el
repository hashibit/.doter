;;; -*- lexical-binding: t -*-
(require 'my-utils)

(defvar dired-mode-map)
(defvar rectangle-mark-mode-map)
(defvar god-local-mode-map)
(defvar projectile-mode-map)



(with-eval-after-load 'dired
  (define-prefix-command 'my-god-mode-leader-key-1)
  (keymap-set dired-mode-map "SPC" 'my-god-mode-leader-key-1)
  (keymap-set dired-mode-map "SPC b" #'switch-to-buffer)
  (keymap-set dired-mode-map "SPC B" #'ibuffer)
  ;; (keymap-set dired-mode-map "SPC k" #'kill-this-buffer)
  (keymap-set dired-mode-map "SPC k" #'kill-current-buffer)
  (keymap-set dired-mode-map "SPC K" #'my-only-current-buffer)
  (keymap-set dired-mode-map "SPC C-k" #'my-only-current-project-buffer)
  (keymap-set dired-mode-map "SPC M-k" #'my-only-current-buffer-include-specials)
  (keymap-set dired-mode-map "SPC f" #'my-projectile-find-file)
  (keymap-set dired-mode-map "SPC p" #'my-find-files)
  (keymap-set dired-mode-map "SPC m" #'deadgrep)
  (keymap-set dired-mode-map "SPC L" #'display-line-numbers-mode)
  (keymap-set dired-mode-map "SPC T" #'toggle-truncate-lines)
  (keymap-set dired-mode-map "SPC x" #'delete-window))   ;; delete this window



(bind-key* (kbd "C-c C-v") #'rectangle-mark-mode)
(with-eval-after-load 'rect
  (keymap-set rectangle-mark-mode-map "i" 'string-rectangle))

;; C-c C-o is preserved by ivy-occur, which is usefull when you want save ivy results to a temp buffer.
;; so we change to C-c o
(bind-key* (kbd "C-c o") #'my-occur)
(bind-key* (kbd "C-c C-s") #'my-rg-at-point)
(bind-key* (kbd "C-c C-,") #'tab-rename)

(bind-key* (kbd "s-j") #'my-toggle-vterm)
(bind-key* (kbd "C-'") #'my-toggle-vterm)
;; terminal need this.
(bind-key* (kbd "C-c v") #'my-toggle-vterm)
;; (bind-key* (kbd "C-`") #'my-toggle-vterm)

(bind-key* (kbd "C-h C-h") #'my-quit-other-window)
(bind-key* (kbd "C-h h")   #'my-quit-other-buffer)

(bind-key* (kbd "C-h C-w") #'ignore)
(bind-key* (kbd "C-x C-b") #'ibuffer)
(bind-key* (kbd "C-x C-f") #'my-find-files)
(bind-key* (kbd "C-x C-k") #'kill-current-buffer)
(bind-key* (kbd "C-c b") #'switch-to-buffer)
(bind-key* (kbd "C-M-b") #'switch-to-buffer)

(bind-key* (kbd "M-RET") #'my-break-to-multiple-lines)
(bind-key* (kbd "M-m")  #'my-toggle-er/mark-inside-paren)
(bind-key* (kbd "M-M")  #'my-toggle-er/mark-outside-paren)
(bind-key (kbd "M-o")  #'ace-window)
(bind-key* (kbd "M-s-o")  #'ff-find-other-file)

(bind-key* (kbd "M-H") #'previous-buffer)
(bind-key* (kbd "M-L") #'next-buffer)

(bind-key* (kbd "M-j") #'gcm-scroll-down)
(bind-key* (kbd "M-k") #'gcm-scroll-up)

(bind-key* (kbd "s-w") #'kill-current-buffer)
(bind-key* (kbd "s-K") #'my/eldoc-box-show-type-definition)
(bind-key* (kbd "s-t") #'tab-bar-new-tab)
(bind-key* (kbd "s-n") #'+funcs/new-empty-buffer)
(bind-key* (kbd "s-N") #'make-frame)

(defun my-eat-new-in-same-window ()
  (interactive)
  (let ((display-buffer-overriding-action '(display-buffer-same-window)))
    (eat nil t)))
(bind-key* (kbd "s-T") #'my-eat-new-in-same-window)

(defun my-split-window-right ()
  (interactive)
  (split-window-right)
  (when (derived-mode-p 'eat-mode)
    (other-window 1)
    (eat nil t)))

(bind-key* (kbd "C-t") #'eat-floating-toggle)
(bind-key* (kbd "s-o") #'eat-floating-toggle)



(defun my-s-c()
  (interactive)
  (if (derived-mode-p 'eat-mode)
    (my-eat-copy-region)
    (call-interactively #'kill-ring-save)))

(bind-key* (kbd "s-c") #'my-s-c)
(defun my-s-v ()
  (interactive)
  (if (derived-mode-p 'eat-mode)
    (eat-yank)
    (yank)))
(bind-key* (kbd "s-v") #'my-s-v)
;; Emacs >= 28: yank 不再自行删除 active region，改由 delete-selection-mode 的
;; pre-hook 按 this-command 的 delete-selection 属性处理。my-s-v 是包装函数，
;; 必须显式声明，否则粘贴不会替换选区（文本重叠）。eat 里返回 nil 保持原样。
(put 'my-s-v 'delete-selection
  (lambda () (unless (derived-mode-p 'eat-mode) 'yank)))
(bind-key* (kbd "s-a") #'mark-whole-buffer)

(bind-key* (kbd "s-<backspace>") #'my-delete-to-bol)

(bind-key* (kbd "s-h") #'tab-previous)
(bind-key* (kbd "s-l") #'tab-next)
;; tab-bar-select-tab 从按键的数字读取 tab 序号
(bind-key* (kbd "s-1") #'tab-bar-select-tab)
(bind-key* (kbd "s-2") #'tab-bar-select-tab)
(bind-key* (kbd "s-3") #'tab-bar-select-tab)
(bind-key* (kbd "s-4") #'tab-bar-select-tab)
(bind-key* (kbd "s-5") #'tab-bar-select-tab)
(bind-key* (kbd "s-6") #'tab-bar-select-tab)
(bind-key* (kbd "s-7") #'tab-bar-select-tab)
(bind-key* (kbd "s-8") #'tab-bar-select-tab)
(bind-key* (kbd "s-9") #'tab-last)

(bind-key* (kbd "s-b") #'treemacs)

(bind-key* (kbd "s-[") #'my-indent-rigidly-left)
(bind-key* (kbd "s-]") #'my-indent-rigidly-right)

(bind-key* (kbd "C-c C-t") #'emacs-translate-dwim)

;; 定义向左缩进函数（每次移动 tab-width 个空格）
(defun my-indent-rigidly-left (start end)
  "向左 rigidly 缩进选中区域一个 tab-width。"
  (interactive
    (if (use-region-p)
      (list (region-beginning) (region-end))
      (list (line-beginning-position) (line-end-position))))
  ;; 禁止任何命令 deactive mark
  (let ((deactivate-mark nil))
    (indent-rigidly start end (- tab-width))
    ))

;; 定义向右缩进函数（每次移动 tab-width 个空格）
(defun my-indent-rigidly-right (start end)
  "向右 rigidly 缩进选中区域一个 tab-width。"
  (interactive
    (if (use-region-p)
      (list (region-beginning) (region-end))
      (list (line-beginning-position) (line-end-position))))
  ;; 禁止任何命令 deactive mark
  (let ((deactivate-mark nil))
    (indent-rigidly start end tab-width)
    ))


;; jump with C-- C-=, like vscode
;; note in terminal emacs, C-/ is translated to C-_, which is undo
(when (display-graphic-p)
  (bind-key* (kbd "C--") 'nice-jumper/backward)
  (bind-key* (kbd "C-_") 'nice-jumper/forward)
  )


(bind-key* (kbd "C-c \\") 'my-toggle-eldoc-box-help-at-point)



(defvar-keymap my-keys-minor-mode-map
  :doc "my-keys-minor-mode keymap."
  "M-x" #'my-M-x
  "C-M-." #'xref-find-definitions-other-window
  "C-M-h" #'my-toggle-er/mark-defun
  "C-s h" #'centaur-tabs-backward
  "C-s l" #'centaur-tabs-forward
  "C-s n" #'centaur-tabs--create-new-tab
  "C-s x" #'centaur-tabs--kill-this-buffer-dont-ask


  "s-d" #'my-mc/mark-next-like-this

  "s-S" #'projectile-ripgrep
  "s-F" #'rg

  ;; "C-M-f" #'projectile-find-file
  ;; "C-x C-b" #'switch-to-buffer

  "C-h ." #'eldoc-doc-buffer

  ;; "C-a" 'mwim-beginning-of-code-or-line
  ;; "C-e" 'mwim-end-of-code-or-line
  "<home>" 'mwim-beginning-of-line-or-code
  "<end>" 'mwim-end-of-line-or-code

  "C-c ." 'er/expand-region


  "M-/" 'my-comment-region-or-line
  "s-/" 'my-comment-region-or-line


  "C-s-," 'xref-go-back
  "C-s-." 'xref-go-forward
  "s-J" 'my-treemacs-add-and-display-current-project

  ;; "M-i" #'er/mark-symbol
  ;; "C-M-;" 'avy-goto-word-0
  "M-s" 'my-save-buffer
  "C-j" 'my-save-buffer
  "C-c j" 'my-save-buffer-without-hooks
  "M-q" 'my-toggle-god-mode

  ;; "M-u" 'upcase-dwim
  ;; "M-l" 'downcase-dwim
  )

(with-eval-after-load 'god-mode
  (define-prefix-command 'my-god-mode-leader-key)
  (define-prefix-command 'my-god-mode-dummmy-key)
  (define-prefix-command 'my-god-mode-eglot-key)
  (define-prefix-command 'my-god-mode-viewer-key)
  (define-prefix-command 'my-god-mode-delete-key)
  (define-prefix-command 'my-god-mode-window-key)
  (define-prefix-command 'my-god-mode-spsexp-key)

  (keymap-set god-local-mode-map "SPC" 'my-god-mode-leader-key)
  (keymap-set god-local-mode-map "," 'my-god-mode-dummmy-key)
  (keymap-set god-local-mode-map "g" 'my-god-mode-eglot-key)
  (keymap-set god-local-mode-map "z" 'my-god-mode-viewer-key)
  (keymap-set god-local-mode-map "d" 'my-god-mode-delete-key)
  (keymap-set god-local-mode-map "q" 'my-god-mode-window-key)
  (keymap-set god-local-mode-map "S" 'my-god-mode-spsexp-key)

  ;; God mode key mappings
  (keymap-set god-local-mode-map "B" #'switch-to-buffer)
  (keymap-set god-local-mode-map "Q" #'my-quit-other-window)

  (keymap-set god-local-mode-map "f" #'avy-goto-word-0)
  (keymap-set god-local-mode-map "t" #'avy-goto-char-in-line)
  (keymap-set god-local-mode-map "w" #'my-forward-to-word)
  (keymap-set god-local-mode-map "b" #'backward-word)
  (keymap-set god-local-mode-map "k" #'my-previous-line)
  (keymap-set god-local-mode-map "j" #'my-next-line)
  (keymap-set god-local-mode-map "l" #'my-forward-char-no-cross-line)
  (keymap-set god-local-mode-map "h" #'my-backward-char-no-cross-line)
  (keymap-set god-local-mode-map "L" #'mwim-end-of-code-or-line)
  (keymap-set god-local-mode-map "H" #'mwim-beginning-of-code-or-line)
  (keymap-set god-local-mode-map "$" #'mwim-end-of-code-or-line)
  (keymap-set god-local-mode-map "0" #'mwim-beginning-of-code-or-line)

  (keymap-set god-local-mode-map "v" #'my-set-mark-command-or-deactivate-mark)
  (keymap-set god-local-mode-map "V" #'my-select-current-line-and-forward-line)
  (keymap-set god-local-mode-map "J" #'my-join-lines)
  (keymap-set god-local-mode-map "y" #'my-copy-whole-line-or-region)
  (keymap-set god-local-mode-map "Y" #'my-copy-whole-line-or-region-to-tmux)
  (keymap-set god-local-mode-map "p" #'my-yank-but-check-newline-bellow)
  (keymap-set god-local-mode-map "P" #'my-yank-but-check-newline-above) ;; same as yank
  (keymap-set god-local-mode-map "u" #'undo-tree-undo)
  (keymap-set god-local-mode-map "C-r" #'undo-tree-redo)
  (keymap-set god-local-mode-map "o" #'my-god-below-newline-and-insert-mode)
  (keymap-set god-local-mode-map "O" #'my-god-above-newline-and-insert-mode)
  (keymap-set god-local-mode-map "a" #'mwim-beginning-of-code-or-line)
  (keymap-set god-local-mode-map "e" #'mwim-end-of-code-or-line)
  (keymap-set god-local-mode-map "i" #'my-quit-god-mode)
  (keymap-set god-local-mode-map "m" #'my-goto-match-paren)

  (keymap-set god-local-mode-map "`" #'popper-toggle-but-other-window)
  (keymap-set god-local-mode-map "M-`" #'popper-cycle-but-other-window)

  (keymap-set god-local-mode-map "s" #'my-replace-char)
  (keymap-set god-local-mode-map "x" #'my-delete-char-or-kill-region)

  (keymap-set god-local-mode-map "<f8>" #'highlight-or-dehighlight-line)
  (keymap-set god-local-mode-map "<f9>" #'remove-all-highlight)

  (keymap-set god-local-mode-map "d d" #'my-kill-whole-line-or-kill-region)
  (keymap-set god-local-mode-map "d j" #'my-kill-whole-line-and-below) ;; TODO point position after kill?
  (keymap-set god-local-mode-map "d k" #'my-kill-whole-line-and-above)
  (keymap-set god-local-mode-map "d w" #'my-kill-word)
  (keymap-set god-local-mode-map "d b" #'backward-kill-word)
  (keymap-set god-local-mode-map "d H" #'my-delete-to-beginning)
  (keymap-set god-local-mode-map "d L" #'my-delete-to-end)
  (keymap-set god-local-mode-map "d G" #'my-delete-to-eof)

  (keymap-set god-local-mode-map "S d" #'sp-delete-sexp)
  (keymap-set god-local-mode-map "S u" #'sp-unwrap-sexp)
  (keymap-set god-local-mode-map "S f" #'sp-forward-sexp)
  (keymap-set god-local-mode-map "S b" #'sp-backward-sexp)

  ;; (keymap-set god-local-mode-map "<RET>" #'next-line)

  (keymap-set god-local-mode-map "z o" #'my-hs-toggle-hiding)
  (keymap-set god-local-mode-map "z m" #'my-hs-toggle-level)
  (keymap-set god-local-mode-map "z z" #'recenter)

  (keymap-set god-local-mode-map "A" #'my-god-mwin-end-and-insert-mode)
  (keymap-set god-local-mode-map "I" #'my-god-mwin-beginning-and-insert-mode)
  (keymap-set god-local-mode-map "E" #'eval-region)

  (keymap-set god-local-mode-map "S i" #'counsel-imenu)
  (keymap-set god-local-mode-map "F" #'my-projectile-find-file)
  (keymap-set god-local-mode-map "M-F" #'my-projectile-switch-project-find-file)

  (keymap-set god-local-mode-map "*" #'my-search-selection)
  (keymap-set god-local-mode-map "/" #'isearch-forward)
  (keymap-set god-local-mode-map "n" #'my-isearch-forward)
  (keymap-set god-local-mode-map "N" #'my-isearch-backward)
  (keymap-set god-local-mode-map ":" #'goto-line)
  (keymap-set god-local-mode-map "RET" #'next-line)
  (keymap-set god-local-mode-map "TAB" #'indent-for-tab-command)
  (keymap-set god-local-mode-map "DEL" #'backward-char)

  (keymap-set god-local-mode-map "C-." #'repeat)
  (keymap-set god-local-mode-map "C-~" #'my-toggle-case-char)

  (keymap-set god-local-mode-map "C-n" #'my-next-line-or-mc/mark-next-like-this)
  (keymap-set god-local-mode-map "C-p" #'my-prev-line-or-mc/mark-next-like-this)

  (keymap-set god-local-mode-map "C-x C-n" #'my-mc/mark-next-like-this)
  (keymap-set god-local-mode-map "C-x C-p" #'my-mc/mark-previous-like-this)

  (keymap-set god-local-mode-map "SPC SPC" #'my-mark-ring)
  (keymap-set god-local-mode-map "SPC b" #'my-project-switch-to-buffer)
  (keymap-set god-local-mode-map "SPC C-b" #'projectile-switch-to-buffer)
  (keymap-set god-local-mode-map "SPC B" #'ibuffer)
  ;; (keymap-set god-local-mode-map "SPC B" #'helm-buffers-list)
  ;; (keymap-set god-local-mode-map "SPC k" #'kill-this-buffer)
  (keymap-set god-local-mode-map "SPC k" #'kill-current-buffer)
  (keymap-set god-local-mode-map "SPC K" #'my-only-current-buffer)
  (keymap-set god-local-mode-map "SPC C-k" #'my-only-current-project-buffer)
  (keymap-set god-local-mode-map "SPC P P" #'xah-copy-file-path)
  (keymap-set god-local-mode-map "SPC M-k" #'my-only-current-buffer-include-specials)

  (keymap-set god-local-mode-map "C-\\" #'my-toggle-eldoc-box-help-at-point)
  (keymap-set god-local-mode-map "SPC R" #'revert-buffer)
  (keymap-set god-local-mode-map "SPC C-r" #'revert-buffer-quick)
  (keymap-set god-local-mode-map "SPC C-s-r" #'my-revert-buffer-no-confirm)

  (keymap-set god-local-mode-map "SPC M-f" #'my-projectile-switch-project-find-file)
  (keymap-set god-local-mode-map "SPC f" #'my-projectile-find-file)
  (keymap-set god-local-mode-map "SPC p" #'my-find-files)
  (keymap-set god-local-mode-map "SPC m" #'deadgrep)
  (keymap-set god-local-mode-map "SPC r" #'rg-dwim)
  (keymap-set god-local-mode-map "SPC o" #'cff-find-other-file)    ;; switch between c header/source file
  (keymap-set god-local-mode-map "SPC L" #'display-line-numbers-mode)
  (keymap-set god-local-mode-map "SPC t" #'my-toggle-truncate-lines-and-word-wrap)
  (keymap-set god-local-mode-map "SPC T" #'my-untabify-buffer)
  (keymap-set god-local-mode-map "SPC x" #'delete-window)   ;; delete this window

  (keymap-set god-local-mode-map "SPC l" #'centaur-tabs-forward)
  (keymap-set god-local-mode-map "SPC h" #'centaur-tabs-backward)

  (keymap-set god-local-mode-map "SPC 2" #'treemacs)
  (keymap-set god-local-mode-map "SPC 3" #'side-ibuffer)
  (keymap-set god-local-mode-map "SPC n" #'my-neotree-toggle)
  (keymap-set god-local-mode-map "SPC N" #'my-neotree-find)
  (keymap-set god-local-mode-map "SPC s" #'counsel-imenu)
  (keymap-set god-local-mode-map "SPC S" #'my-occur)
  (keymap-set god-local-mode-map "SPC i" #'imenu-list-smart-toggle)
  (keymap-set god-local-mode-map "SPC I" #'my-imenu-filter-struct-eglot)


  (keymap-set god-local-mode-map "SPC a s" #'my-eat-claude-send-region)
  (keymap-set god-local-mode-map "SPC a b" #'my-eat-claude-send-buffer)

  (keymap-set god-local-mode-map "@" #'my-treemacs-add-and-display-current-project)
  (keymap-set god-local-mode-map "SPC @" #'treemacs-add-and-display-current-project)

  ;; (keymap-set god-local-mode-map "q l" #'windmove-right)
  ;; (keymap-set god-local-mode-map "q h" #'windmove-left)
  ;; (keymap-set god-local-mode-map "q k" #'windmove-up)
  ;; (keymap-set god-local-mode-map "q j" #'windmove-down)
  ;; (keymap-set god-local-mode-map "q v" #'split-window-right)
  ;; (keymap-set god-local-mode-map "q s" #'split-window-below)
  ;; (keymap-set god-local-mode-map "q t" #'transpose-frame)
  ;; (keymap-set god-local-mode-map "q TAB" #'other-window)
  ;; (keymap-set god-local-mode-map "q x" #'delete-window)         ;; delete this window
  (keymap-set god-local-mode-map "q q" #'my-quit-other-window)  ;; delete other window

  (keymap-set god-local-mode-map ", w" #'my-save-buffer)
  (keymap-set god-local-mode-map ", b" #'my-flip-buffer-to-window-in-project)
  (keymap-set god-local-mode-map ", B" #'my-flip-buffer-to-window-include-special)

  (keymap-set god-local-mode-map ", s" #'emacs-surround)

  (keymap-set god-local-mode-map ", r r" #'httpd-start)
  (keymap-set god-local-mode-map ", r k" #'httpd-stop)
  (keymap-set god-local-mode-map ", ," #'my-quit-other-window)

  (keymap-set god-local-mode-map ", i \"" #'er/mark-inside-quotes)
  (keymap-set god-local-mode-map ", a \"" #'er/mark-outside-quotes)

  (keymap-set god-local-mode-map "g d" #'xref-find-definitions)
  (keymap-set god-local-mode-map "g r" #'xref-find-references)
  (keymap-set god-local-mode-map "g R" #'eglot-rename)
  (keymap-set god-local-mode-map "g i" #'eglot-find-implementation)
  (keymap-set god-local-mode-map "g a" #'eglot-code-actions)
  (keymap-set god-local-mode-map "g q" #'eglot-reconnect)
  (keymap-set god-local-mode-map "g g" #'beginning-of-buffer)
  (keymap-set god-local-mode-map "G" #'end-of-buffer)
  (keymap-set god-local-mode-map "g G" #'end-of-buffer)
  ;; (keymap-set god-local-mode-map "C-e" #'scroll-up-line)
  ;; (keymap-set god-local-mode-map "C-y" #'scroll-down-line)
  ;; (keymap-set god-local-mode-map "C-a" #'increment-number-at-point)

  ;; (keymap-set god-local-mode-map "C-, C-h" #'switch-to-prev-buffer)
  ;; (keymap-set god-local-mode-map "C-, C-l" #'switch-to-next-buffer)

  ;; (my-key-chord-define god-local-mode-map ",,"  #'er/mark-symbol)

  ;; (keymap-set god-local-mode-map "C-m" #'next-line)

  ;; (keymap-set god-local-mode-map "C-d" #'scroll-up-command)
  ;; (keymap-set god-local-mode-map "C-u" #'scroll-down-command)
  ;; (keymap-set god-local-mode-map "C-f" #'scroll-full-page-up)
  ;; (keymap-set god-local-mode-map "C-b" #'scroll-full-page-down)

  (keymap-set god-local-mode-map ";" #'scroll-up-command)
  (keymap-set god-local-mode-map "'" #'scroll-down-command)
  ;; (keymap-set god-local-mode-map "\\" #'recenter-top-bottom)
  )

(with-eval-after-load 'lisp-mode
  (keymap-set lisp-mode-map "C-c C-e" #'eval-region))
(with-eval-after-load 'elisp-mode
  (keymap-set emacs-lisp-mode-map "C-c C-e" #'eval-region))

;; projectile
(with-eval-after-load 'projectile
  (keymap-set projectile-mode-map "C-c f" 'projectile-command-map))

(defun my-kill-whole-line-and-below ()
  (interactive)
  (kill-whole-line 2))

(defun my-kill-whole-line-and-above ()
  (interactive)
  (kill-whole-line -2))

(defun my-flip-buffer-to-window-include-special ()
  (interactive)
  (flip-buffer-to-window t))

(define-minor-mode my-keys-minor-mode
  "A minor mode so that my key settings override annoying major modes."
  :init-value nil
  :lighter " my-keys")




(defvar-keymap my-special-buffer-keys-minor-mode-map
  :doc "my-special-buffer-keys-minor-mode keymap."
  ";" #'scroll-up-command
  "'" #'scroll-down-command
  "/" #'isearch-forward
  "k" #'previous-line
  "j" #'next-line
  "l" #'my-forward-char-no-cross-line
  "h" #'my-backward-char-no-cross-line
  "L" #'mwim-end-of-code-or-line
  "H" #'mwim-beginning-of-code-or-line
  "v" #'my-set-mark-command-or-deactivate-mark
  "V" #'my-select-current-line-and-forward-line

  "f" #'avy-goto-word-0
  "M-x" #'my-M-x)
(define-minor-mode my-special-buffer-keys-minor-mode
  "A minor mode add some bindings for special-buffers."
  :init-value nil
  :lighter " my-special-buffer-keys")



(bind-keys* :prefix-map my-ctrl-w-window-operations-map
  :prefix "C-w"
  ("o" . ace-window)
  ("l" . windmove-right)
  ("h" . windmove-left)
  ("k" . windmove-up)
  ("j" . windmove-down)
  ("Q" . delete-window)
  ("d" . delete-other-windows)
  ("v" . my-split-window-right)
  ("s" . split-window-below)
  ("t" . transpose-frame)
  ("w" . other-window)

  ("]" . my-enlarge-half-width)
  ("[" . my-shrink-half-width)
  ("=" . my-enlarge-half-height)
  ("-" . my-shrink-half-height)

  ("C-l" . windmove-right)
  ("C-h" . windmove-left)
  ("C-k" . windmove-up)
  ("C-j" . windmove-down)
  ("C-n" . treemacs-next-workspace)
  ("`" . my-enarge-window-height)
  )





(unless (display-graphic-p)
  (with-eval-after-load 'centaur-tabs
    (keymap-set my-special-buffer-keys-minor-mode-map "C-s h" #'centaur-tabs-backward)
    (keymap-set my-special-buffer-keys-minor-mode-map "C-s l" #'centaur-tabs-forward)
    (keymap-set my-special-buffer-keys-minor-mode-map "C-s n" #'centaur-tabs--create-new-tab)
    )
  )


(provide 'my-key-bindings)
