(require 'my-utils)



(eval-after-load "dired"
  '(progn
     (define-prefix-command 'my-god-mode-leader-key-1)
     (define-key dired-mode-map (kbd "SPC") 'my-god-mode-leader-key-1)
     (define-key dired-mode-map (kbd "SPC b") #'switch-to-buffer)
     (define-key dired-mode-map (kbd "SPC B") #'ibuffer)
     ;; (define-key dired-mode-map (kbd "SPC k") #'kill-this-buffer)
     (define-key dired-mode-map (kbd "SPC k") #'kill-current-buffer)
     (define-key dired-mode-map (kbd "SPC K") #'my-only-current-buffer)
     (define-key dired-mode-map (kbd "SPC M-k") #'my-only-current-buffer-include-specials)
     (define-key dired-mode-map (kbd "SPC f") #'my-projectile-find-file)
     (define-key dired-mode-map (kbd "SPC p") #'my-find-files)
     (define-key dired-mode-map (kbd "SPC m") #'deadgrep)
     (define-key dired-mode-map (kbd "SPC L") #'display-line-numbers-mode)
     (define-key dired-mode-map (kbd "SPC T") #'toggle-truncate-lines)
     (define-key dired-mode-map (kbd "SPC x") #'delete-window)   ;; delete this window
     ))



(bind-key* (kbd "C-c C-v") #'rectangle-mark-mode)
(with-eval-after-load 'rect
  (define-key rectangle-mark-mode-map (kbd "i") 'string-rectangle))

;; C-c C-o is preserved by ivy-occur, which is usefull when you want save ivy results to a temp buffer.
;; so we change to C-c o
(bind-key* (kbd "C-c o") #'my-occur)
(bind-key* (kbd "C-c C-s") #'my-rg-at-point)

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
(bind-key* (kbd "C-x C-k") #'kill-this-buffer)
(bind-key* (kbd "C-c b") #'switch-to-buffer)
(bind-key* (kbd "C-M-b") #'switch-to-buffer)

(bind-key* (kbd "M-RET") #'my-break-to-multiple-lines)
(bind-key* (kbd "M-m")  #'my-toggle-er/mark-inside-paren)
(bind-key* (kbd "M-M")  #'my-toggle-er/mark-outside-paren)
(bind-key* (kbd "M-o")  #'ace-window)
(bind-key* (kbd "M-s-o")  #'ff-find-other-file)

(bind-key* (kbd "M-H") #'previous-buffer)
(bind-key* (kbd "M-L") #'next-buffer)

(bind-key* (kbd "M-j") #'gcm-scroll-down)
(bind-key* (kbd "M-k") #'gcm-scroll-up)

(bind-key* (kbd "s-w") #'kill-current-buffer)
(bind-key* (kbd "s-k") #'my-toggle-eldoc-box-help-at-point)
(bind-key* (kbd "s-t") #'+funcs/new-empty-buffer)

(bind-key* (kbd "s-T") #'multi-vterm)
(bind-key* (kbd "C-t") #'claude-code-toggle)
(bind-key* (kbd "s-o") #'claude-code-toggle)


(bind-key* (kbd "s-c") #'kill-ring-save)
(bind-key* (kbd "s-v") #'yank)
(bind-key* (kbd "s-a") #'mark-whole-buffer)

(bind-key* (kbd "s-<backspace>") #'my-delete-to-bol)

(bind-key* (kbd "s-h") #'tab-previous)
(bind-key* (kbd "s-l") #'tab-next)
(bind-key* (kbd "s-1") #'(lambda() (interactive) (tab-bar-select-tab 1)))
(bind-key* (kbd "s-2") #'(lambda() (interactive) (tab-bar-select-tab 2)))
(bind-key* (kbd "s-3") #'(lambda() (interactive) (tab-bar-select-tab 3)))
(bind-key* (kbd "s-4") #'(lambda() (interactive) (tab-bar-select-tab 4)))
(bind-key* (kbd "s-5") #'(lambda() (interactive) (tab-bar-select-tab 5)))
(bind-key* (kbd "s-9") #'(lambda() (interactive) (tab-bar-select-tab (length (tab-bar-tabs)))))

(bind-key* (kbd "s-b") #'treemacs)

(bind-key* (kbd "s-[") #'indent-rigidly-left)
(bind-key* (kbd "s-]") #'indent-rigidly-right)

(bind-key* (kbd "C-c C-t") #'emacs-translate-dwim)

;; 定义向左缩进函数（每次移动 tab-width 个空格）
(defun indent-rigidly-left (start end)
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
(defun indent-rigidly-right (start end)
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



(defvar my-keys-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-x") #'my-M-x)
    (define-key map (kbd "C-M-.") #'xref-find-definitions-other-window )
    (define-key map (kbd "C-M-h") #'my-toggle-er/mark-defun)
    (define-key map (kbd "C-s h")  #'centaur-tabs-backward)
    (define-key map (kbd "C-s l")  #'centaur-tabs-forward)
    (define-key map (kbd "C-s n")  #'centaur-tabs--create-new-tab)
    (define-key map (kbd "C-s x")  #'centaur-tabs--kill-this-buffer-dont-ask)


    (define-key map (kbd "s-d") #'my-mc/mark-next-like-this)

    (define-key map (kbd "s-S") #'projectile-ripgrep)
    (define-key map (kbd "s-F") #'rg)

    ;; (define-key map (kbd "C-M-f") #'projectile-find-file)
    ;; (define-key map (kbd "C-x C-b") #'switch-to-buffer)

    (define-key map (kbd "C-h .") #'eldoc-doc-buffer)


    (define-key lisp-mode-map (kbd "C-c C-e") #'eval-region)

    ;; (define-key map (kbd "C-a") 'mwim-beginning-of-code-or-line)
    ;; (define-key map (kbd "C-e") 'mwim-end-of-code-or-line)
    (define-key map (kbd "<home>") 'mwim-beginning-of-line-or-code)
    (define-key map (kbd "<end>") 'mwim-end-of-line-or-code)

    (define-key map (kbd "C-c .") 'er/expand-region)


    (define-key map (kbd "M-/") 'my-comment-region-or-line)
    (define-key map (kbd "s-/") 'my-comment-region-or-line)


    (define-key map (kbd "C-s-,") 'xref-go-back)
    (define-key map (kbd "C-s-.") 'xref-go-forward)
    (define-key map (kbd "s-J") 'my-treemacs-add-and-display-current-project)

    ;; (define-key map (kbd "M-i") #'er/mark-symbol)
    ;; (define-key map (kbd "C-M-;") 'avy-goto-word-0)
    (define-key map (kbd "M-s") 'my-save-buffer)
    (define-key map (kbd "C-j") 'my-save-buffer)
    (define-key map (kbd "C-c j") 'my-save-buffer-without-hooks)
    (define-key map (kbd "M-q") 'my-toggle-god-mode)

    ;; (define-key map (kbd "M-u") 'upcase-dwim)
    ;; (define-key map (kbd "M-l") 'downcase-dwim)


    (define-prefix-command 'my-god-mode-leader-key)
    (define-prefix-command 'my-god-mode-dummmy-key)
    (define-prefix-command 'my-god-mode-eglot-key)
    (define-prefix-command 'my-god-mode-viewer-key)
    (define-prefix-command 'my-god-mode-delete-key)
    (define-prefix-command 'my-god-mode-window-key)
    (define-prefix-command 'my-god-mode-spsexp-key)

    (define-key god-local-mode-map (kbd "SPC") 'my-god-mode-leader-key)
    (define-key god-local-mode-map (kbd ",")   'my-god-mode-dummmy-key)
    (define-key god-local-mode-map (kbd "g")   'my-god-mode-eglot-key)
    (define-key god-local-mode-map (kbd "z")   'my-god-mode-viewer-key)
    (define-key god-local-mode-map (kbd "d")   'my-god-mode-delete-key)
    (define-key god-local-mode-map (kbd "q")   'my-god-mode-window-key)
    (define-key god-local-mode-map (kbd "S")   'my-god-mode-spsexp-key)

    ;; God mode key mappings
    (define-key god-local-mode-map (kbd "B") #'switch-to-buffer)
    (define-key god-local-mode-map (kbd "Q") #'my-quit-other-window)

    (define-key god-local-mode-map (kbd "f") #'avy-goto-word-0)
    (define-key god-local-mode-map (kbd "t") #'avy-goto-char-in-line)
    (define-key god-local-mode-map (kbd "w") #'my-forward-to-word)
    (define-key god-local-mode-map (kbd "b") #'backward-word)
    (define-key god-local-mode-map (kbd "k") #'my-previous-line)
    (define-key god-local-mode-map (kbd "j") #'my-next-line)
    (define-key god-local-mode-map (kbd "l") #'my-forward-char-no-cross-line)
    (define-key god-local-mode-map (kbd "h") #'my-backward-char-no-cross-line)
    (define-key god-local-mode-map (kbd "L") #'mwim-end-of-code-or-line)
    (define-key god-local-mode-map (kbd "H") #'mwim-beginning-of-code-or-line)
    (define-key god-local-mode-map (kbd "$") #'mwim-end-of-code-or-line)
    (define-key god-local-mode-map (kbd "0") #'mwim-beginning-of-code-or-line)

    (define-key god-local-mode-map (kbd "v") #'my-set-mark-command-or-deactivate-mark)
    (define-key god-local-mode-map (kbd "V") #'my-select-current-line-and-forward-line)
    (define-key god-local-mode-map (kbd "J") #'my-join-lines)
    (define-key god-local-mode-map (kbd "y") #'my-copy-whole-line-or-region)
    (define-key god-local-mode-map (kbd "Y") #'my-copy-whole-line-or-region-to-tmux)
    (define-key god-local-mode-map (kbd "p") #'my-yank-but-check-newline-bellow)
    (define-key god-local-mode-map (kbd "P") #'my-yank-but-check-newline-above) ;; same as yank
    (define-key god-local-mode-map (kbd "u") #'undo-tree-undo)
    (define-key god-local-mode-map (kbd "C-r") #'undo-tree-redo)
    (define-key god-local-mode-map (kbd "o") #'my-god-below-newline-and-insert-mode)
    (define-key god-local-mode-map (kbd "O") #'my-god-above-newline-and-insert-mode)
    (define-key god-local-mode-map (kbd "a") #'mwim-beginning-of-code-or-line)
    (define-key god-local-mode-map (kbd "e") #'mwim-end-of-code-or-line)
    (define-key god-local-mode-map (kbd "i") #'my-quit-god-mode)
    (define-key god-local-mode-map (kbd "m") #'my-goto-match-paren)

    (define-key god-local-mode-map (kbd "`") #'popper-toggle-but-other-window)
    (define-key god-local-mode-map (kbd "M-`") #'popper-cycle-but-other-window)

    (define-key god-local-mode-map (kbd "s") #'my-replace-char)
    (define-key god-local-mode-map (kbd "x") #'my-delete-char-or-kill-region)

    (define-key god-local-mode-map (kbd "<f8>") #'highlight-or-dehighlight-line)
    (define-key god-local-mode-map (kbd "<f9>") #'remove-all-highlight)

    (define-key god-local-mode-map (kbd "d d") #'my-kill-whole-line-or-kill-region)
    (define-key god-local-mode-map (kbd "d j") #'(lambda () (interactive) (kill-whole-line 2))) ;; TODO point position after kill?
    (define-key god-local-mode-map (kbd "d k") #'(lambda () (interactive) (kill-whole-line -2)))
    (define-key god-local-mode-map (kbd "d w") #'my-kill-word)
    (define-key god-local-mode-map (kbd "d b") #'backward-kill-word)
    (define-key god-local-mode-map (kbd "d H") #'my-delete-to-beginning)
    (define-key god-local-mode-map (kbd "d L") #'my-delete-to-end)
    (define-key god-local-mode-map (kbd "d G") #'my-delete-to-eof)

    (define-key god-local-mode-map (kbd "S d") #'sp-delete-sexp)
    (define-key god-local-mode-map (kbd "S u") #'sp-unwrap-sexp)
    (define-key god-local-mode-map (kbd "S f") #'sp-forward-sexp)
    (define-key god-local-mode-map (kbd "S b") #'sp-backward-sexp)

    ;; (define-key god-local-mode-map (kbd "<RET>") #'next-line)

    (define-key god-local-mode-map (kbd "z o") #'my-hs-toggle-hiding)
    (define-key god-local-mode-map (kbd "z m") #'my-hs-toggle-all)
    (define-key god-local-mode-map (kbd "z z") #'recenter)

    (define-key god-local-mode-map (kbd "A") #'my-god-mwin-end-and-insert-mode)
    (define-key god-local-mode-map (kbd "I") #'my-god-mwin-beginning-and-insert-mode)
    (define-key god-local-mode-map (kbd "E") #'eval-region)

    (define-key god-local-mode-map (kbd "S") #'counsel-imenu)
    (define-key god-local-mode-map (kbd "F") #'my-projectile-find-file)
    (define-key god-local-mode-map (kbd "M-F") #'my-projectile-switch-project-find-file)

    (define-key god-local-mode-map (kbd "*") #'my-search-selection)
    (define-key god-local-mode-map (kbd "/") #'isearch-forward)
    (define-key god-local-mode-map (kbd "n") #'my-isearch-forward)
    (define-key god-local-mode-map (kbd "N") #'my-isearch-backward)
    (define-key god-local-mode-map (kbd ":") #'goto-line)
    (define-key god-local-mode-map (kbd "RET") #'next-line)
    (define-key god-local-mode-map (kbd "TAB") #'indent-for-tab-command)
    (define-key god-local-mode-map (kbd "DEL") #'backward-char)

    (define-key god-local-mode-map (kbd "C-.") #'repeat)
    (define-key god-local-mode-map (kbd "C-~") #'my-toggle-case-char)

    (define-key god-local-mode-map (kbd "C-n") #'my-next-line-or-mc/mark-next-like-this)
    (define-key god-local-mode-map (kbd "C-p") #'my-prev-line-or-mc/mark-next-like-this)

    (define-key god-local-mode-map (kbd "C-x C-n") #'my-mc/mark-next-like-this)
    (define-key god-local-mode-map (kbd "C-x C-p") #'my-mc/mark-previous-like-this)

    (define-key god-local-mode-map (kbd "SPC SPC") #'my-mark-ring)
    (define-key god-local-mode-map (kbd "SPC b") #'counsel-switch-buffer)
    (define-key god-local-mode-map (kbd "SPC C-b") #'projectile-switch-to-buffer)
    (define-key god-local-mode-map (kbd "SPC B") #'ibuffer)
    ;; (define-key god-local-mode-map (kbd "SPC B") #'helm-buffers-list)
    ;; (define-key god-local-mode-map (kbd "SPC k") #'kill-this-buffer)
    (define-key god-local-mode-map (kbd "SPC k") #'kill-current-buffer)
    (define-key god-local-mode-map (kbd "SPC K") #'my-only-current-buffer)
    (define-key god-local-mode-map (kbd "SPC P P") #'xah-copy-file-path)
    (define-key god-local-mode-map (kbd "SPC M-k") #'my-only-current-buffer-include-specials)

    (define-key god-local-mode-map (kbd "C-\\") #'my-toggle-eldoc-box-help-at-point)
    (define-key god-local-mode-map (kbd "SPC R") #'revert-buffer)
    (define-key god-local-mode-map (kbd "SPC C-r") #'revert-buffer-quick)

    (define-key god-local-mode-map (kbd "SPC M-f") #'my-projectile-switch-project-find-file)
    (define-key god-local-mode-map (kbd "SPC f") #'my-projectile-find-file)
    (define-key god-local-mode-map (kbd "SPC p") #'my-find-files)
    (define-key god-local-mode-map (kbd "SPC m") #'deadgrep)
    (define-key god-local-mode-map (kbd "SPC r") #'rg-dwim)
    (define-key god-local-mode-map (kbd "SPC o") #'cff-find-other-file)    ;; switch between c header/source file
    (define-key god-local-mode-map (kbd "SPC L") #'display-line-numbers-mode)
    (define-key god-local-mode-map (kbd "SPC t") #'my-toggle-truncate-lines-and-word-wrap)
    (define-key god-local-mode-map (kbd "SPC T") #'my-untabify-buffer)
    (define-key god-local-mode-map (kbd "SPC x") #'delete-window)   ;; delete this window

    (define-key god-local-mode-map (kbd "SPC l") #'centaur-tabs-forward)
    (define-key god-local-mode-map (kbd "SPC h") #'centaur-tabs-backward)

    (define-key god-local-mode-map (kbd "SPC 2") #'treemacs)
    (define-key god-local-mode-map (kbd "SPC 3") #'side-ibuffer)
    (define-key god-local-mode-map (kbd "SPC n") #'my-neotree-toggle)
    (define-key god-local-mode-map (kbd "SPC N") #'my-neotree-find)
    (define-key god-local-mode-map (kbd "SPC s") #'counsel-imenu)
    (define-key god-local-mode-map (kbd "SPC S") #'my-occur)
    (define-key god-local-mode-map (kbd "SPC i") #'imenu-list-smart-toggle)
    (define-key god-local-mode-map (kbd "SPC I") #'my-imenu-list-smart-toggle-refresh)


    (define-key god-local-mode-map (kbd "SPC a s") #'claude-code-send-region)
    (define-key god-local-mode-map (kbd "SPC a b") #'claude-code-send-buffer-file)

    (define-key god-local-mode-map (kbd "@") #'my-treemacs-add-and-display-current-project)
    (define-key god-local-mode-map (kbd "SPC @") #'treemacs-add-and-display-current-project)

    ;; (define-key god-local-mode-map (kbd "q l") #'windmove-right)
    ;; (define-key god-local-mode-map (kbd "q h") #'windmove-left)
    ;; (define-key god-local-mode-map (kbd "q k") #'windmove-up)
    ;; (define-key god-local-mode-map (kbd "q j") #'windmove-down)
    ;; (define-key god-local-mode-map (kbd "q v") #'split-window-right)
    ;; (define-key god-local-mode-map (kbd "q s") #'split-window-below)
    ;; (define-key god-local-mode-map (kbd "q t") #'transpose-frame)
    ;; (define-key god-local-mode-map (kbd "q TAB") #'other-window)
    ;; (define-key god-local-mode-map (kbd "q x") #'delete-window)         ;; delete this window
    (define-key god-local-mode-map (kbd "q q") #'my-quit-other-window)  ;; delete other window

    (define-key god-local-mode-map (kbd ", w") #'my-save-buffer)
    (define-key god-local-mode-map (kbd ", b") #'flip-buffer-to-window)
    (define-key god-local-mode-map (kbd ", B") #'(lambda () (interactive) (flip-buffer-to-window t)))

    (define-key god-local-mode-map (kbd ", s") #'emacs-surround)

    (define-key god-local-mode-map (kbd ", r r") #'httpd-start)
    (define-key god-local-mode-map (kbd ", r k") #'httpd-stop)
    (define-key god-local-mode-map (kbd ", ,") #'my-quit-other-window)

    (define-key god-local-mode-map (kbd ", i \"") #'er/mark-inside-quotes)
    (define-key god-local-mode-map (kbd ", a \"") #'er/mark-outside-quotes)

    (define-key god-local-mode-map (kbd "g d") #'xref-find-definitions)
    (define-key god-local-mode-map (kbd "g r") #'xref-find-references)
    (define-key god-local-mode-map (kbd "g R") #'eglot-rename)
    (define-key god-local-mode-map (kbd "g i") #'eglot-find-implementation)
    (define-key god-local-mode-map (kbd "g a") #'eglot-code-actions)
    (define-key god-local-mode-map (kbd "g q") #'eglot-reconnect)
    (define-key god-local-mode-map (kbd "g g") #'beginning-of-buffer)
    (define-key god-local-mode-map (kbd "G") #'end-of-buffer)
    (define-key god-local-mode-map (kbd "g G") #'end-of-buffer)
    ;; (define-key god-local-mode-map (kbd "C-e") #'scroll-up-line)
    ;; (define-key god-local-mode-map (kbd "C-y") #'scroll-down-line)
    ;; (define-key god-local-mode-map (kbd "C-a") #'increment-number-at-point)

    ;; (define-key god-local-mode-map (kbd "C-, C-h") #'switch-to-prev-buffer)
    ;; (define-key god-local-mode-map (kbd "C-, C-l") #'switch-to-next-buffer)

    ;; (my-key-chord-define god-local-mode-map ",,"  #'er/mark-symbol)

    ;; (define-key god-local-mode-map (kbd "C-m") #'next-line)

    ;; (define-key god-local-mode-map (kbd "C-d") #'scroll-up-command)
    ;; (define-key god-local-mode-map (kbd "C-u") #'scroll-down-command)
    ;; (define-key god-local-mode-map (kbd "C-f") #'scroll-full-page-up)
    ;; (define-key god-local-mode-map (kbd "C-b") #'scroll-full-page-down)

    (define-key god-local-mode-map (kbd ";") #'scroll-up-command)
    (define-key god-local-mode-map (kbd "'") #'scroll-down-command)
    ;; (define-key god-local-mode-map (kbd "\\") #'recenter-top-bottom)


    ;; projectile
    (define-key projectile-mode-map (kbd "C-c f") 'projectile-command-map)
    map)
  "my-keys-minor-mode keymap.")

(define-minor-mode my-keys-minor-mode
  "A minor mode so that my key settings override annoying major modes."
  :init-value nil
  :lighter " my-keys")




(defvar my-special-buffer-keys-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd ";") #'scroll-up-command)
    (define-key map (kbd "'") #'scroll-down-command)
    (define-key map (kbd "/") #'isearch-forward)
    (define-key map (kbd "k") #'previous-line)
    (define-key map (kbd "j") #'next-line)
    (define-key map (kbd "l") #'my-forward-char-no-cross-line)
    (define-key map (kbd "h") #'my-backward-char-no-cross-line)
    (define-key map (kbd "L") #'mwim-end-of-code-or-line)
    (define-key map (kbd "H") #'mwim-beginning-of-code-or-line)
    (define-key map (kbd "v") #'my-set-mark-command-or-deactivate-mark)
    (define-key map (kbd "V") #'my-select-current-line-and-forward-line)

    (define-key map (kbd "f") #'avy-goto-word-0)
    (define-key map (kbd "M-x") #'my-M-x)

    map)
  "my-special-buffer-keys-minor-mode keymap.")
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
  ("v" . split-window-right)
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
  ("`" . my-enarge-window-height)
  )





(unless (display-graphic-p)
  (with-eval-after-load 'centaur-tabs
    (define-key my-keys-minor-mode-map (kbd "C-s h") #'centaur-tabs-backward)
    (define-key my-keys-minor-mode-map (kbd "C-s l") #'centaur-tabs-forward)
    (define-key my-keys-minor-mode-map (kbd "C-s n") #'centaur-tabs--create-new-tab)
    (define-key my-special-buffer-keys-minor-mode-map (kbd "C-s h") #'centaur-tabs-backward)
    (define-key my-special-buffer-keys-minor-mode-map (kbd "C-s l") #'centaur-tabs-forward)
    (define-key my-special-buffer-keys-minor-mode-map (kbd "C-s n") #'centaur-tabs--create-new-tab)
    )
  )


(provide 'my-key-bindings)
