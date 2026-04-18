;; -*- lexical-binding: t -*-
;;; init-god.el --- God mode configuration

(require 'god-mode)

(setq god-exempt-major-modes nil
      god-exempt-predicates nil
      god-mode-alist '((nil . "C-") ("r" . "M-") ("R" . "C-M-")))

;; special-buffers are not affected by god-mode bindings, but affected by my-special-buffer-keys-minor-mode-map
(setq special-buffer-modes
  (list
    "dired-mode"
    "ibuffer-mode"
    "special-mode"
    "native-comp-limple-mode"
    "ivy-occur-mode"
    "image-mode"
    ))

(setq special-buffers (list
                       "*Pos-Frame-Read*"
                       "*Treemacs"
                       "*Messages*"
                       "*compilation*"
                       "HELLO"
                       "*Ibuffer*"
                       "*deadgrep"
                       "*rg*"
                       "*xref"
                       "*Buffer"
                       "*Annotate"
                       "*Completions*"
                       "*vc-diff*"
                       "*Packages"
                       "*lsp-log*"
                       "*Help*"
                       "*Ivy"
                       "*Occur*"
                       "*info*"
                       "*Warnings*"
                       "helm-*"
                       "*Helm Help*"
                       "*Flymake"
                       "*ansi-term*"
                       "*fzf*"
                       "*Ilist*"
                       "*NeoTree*"))


;; legendary-buffers are not affected by god-mode AND my-special-buffer-keys-minor-mode-map
(setq legendary-buffers (list
                         "*this-buffer-is-left-alone-without-god-mode-at-all"
                         "*Minibuf"
                         "*Compile"
                         "*EGLOT"
                         "*terminal*"
                         "*vterm"
                         "*claude"
                         "*emacs"
                         "*eshell*"
                         "*blink-search"
                         "*ripgrep-search*"
                         "*blink search"
                         "*shell*"
                         "*dashboard*"
                         "*slime"
                         "*sldb"
                         "*leetcode"
                         "magit"
                         "git-rebase-todo"
                         "*Backtrace*"
                         "menu"
                         "*ielm*"
                         "*Gofmt"
                         "*slime-repl"
                         "*Customize"))

(setq legendary-modes (list
                       "*this-buffer-is-left-alone-without-god-mode-at-all"
                       "cfrs-input-mode"
                       "help-mode"
                       "xwidget-webkit-mode"
                       "slime-mode"
                       "cider-repl-mode"
                       "minibuffer-mode"
                       "eat-mode"
                       "inferior-python-mode"
                       "fundamental-mode"
                       "cnfonts-ui-mode"
                       "deadgrep-edit-mode"))


(defun my-change-buffer-name-from-special-to-legendary(buffer-name)
  (setq special-buffers (remove buffer-name special-buffers))
  (add-to-list 'legendary-buffers buffer-name))

(defun my-change-buffer-name-from-legendary-to-special(buffer-name)
  (setq legendary-buffers (remove buffer-name legendary-buffers))
  (add-to-list 'special-buffers buffer-name))


(defun my-add-to-legendary-buffers(buffer-names)
  (dolist (element (if (listp buffer-names) buffer-names (list buffer-names)))
    (add-to-list 'legendary-buffers element)))

(defun my-remove-from-legendary-buffers(buffer-names)
  (dolist (element (if (listp buffer-names) buffer-names (list buffer-names)))
  (setq legendary-buffers (remove element legendary-buffers))))

(defun my-god-this-is-special-buffer (bufname)
  "Check if BUFNAME is a special buffer."
  (interactive)
  (let ((this-buffer-name (string-trim bufname))
        (this-buffer-mode (symbol-name (buffer-mode bufname))))
    (or
     (seq-filter
      (lambda (n) (string-prefix-p n this-buffer-name))
      special-buffers)
     (seq-filter
      (lambda (n) (string-prefix-p n this-buffer-mode))
      special-buffer-modes))))

(defun my-god-this-is-legendary-buffer (bufname)
  "Check if BUFNAME is a legendary buffer."
  (interactive)
  ;; (message "buffer-mode type is %s" (type-of (buffer-mode bufname))) ==> symbol
  ;;;; use symbol-name convert symbol to string; And for the reverse, (intern "some-string") to get symbol
  (let ((this-buffer-name (string-trim bufname))
        (this-buffer-mode (symbol-name (buffer-mode bufname))))
    ;; (message "this-buffer-name %s" this-buffer-name)
    ;; (message "this-buffer-mode %s" this-buffer-mode)
    (or
     (seq-filter
      (lambda (n) (string-prefix-p n this-buffer-name))
      legendary-buffers)
     (seq-filter
      (lambda (n) (string-prefix-p n this-buffer-mode))
      legendary-modes))))

(defun my-god-this-is-normal-editor-buffer (bufname)
  "Check if BUFNAME is a normal editor buffer."
  (interactive)
  (not
   (or (my-god-this-is-special-buffer bufname)
       (my-god-this-is-legendary-buffer bufname))))

(defun my-god-should-enable-hi-line-mode ()
  "Check if hi-line mode should be enabled."
  (interactive)
  (not (bound-and-true-p smerge-mode)))

(defun my-god-should-enable-line-number-mode()
  "Check if line number mode should be enabled."
  (not (derived-mode-p 'vterm-mode)))

(setq should-not-display-dark-background-modes (list
                                                 "dired-mode"
                                                 "vterm-mode"
                                                 "eldoc-box-mode"
                                                 "xwidget-webkit-mode"
                                                 "minibuffer-mode"
                                                 "dashboard-mode"))

(setq should-not-display-no-paddings-modes (list
                                             "xwidget-webkit-mode"))
(defun my/set-margins-all-windows ()
  "给所有窗口设置边距，排除指定的 major mode"
  (dolist (window (window-list))
    (with-current-buffer (window-buffer window)
      (if (member (symbol-name major-mode) should-not-display-no-paddings-modes)
        (set-window-margins window 0 0)      ; 排除的模式设置为0
        (set-window-margins window 1 1)))))  ; 其他模式设置边距

;; 在窗口配置改变时自动设置边距
(add-hook 'window-configuration-change-hook #'my/set-margins-all-windows)


(defun my-god-this-is-dark-background-buffer (bufname)
  "Check if BUFNAME should have dark background."
  (interactive)
  (let ((this-buffer-name (string-trim bufname))
         (this-buffer-mode (symbol-name (buffer-mode bufname))))
    (not
      (or
        ;; Check if buffer name matches (for eldoc-box and similar)
        (string-prefix-p "*eldoc-box*" this-buffer-name)
        ;; Check if major-mode matches
        (seq-filter
          (lambda (n) (string-prefix-p n this-buffer-mode))
          should-not-display-dark-background-modes)))))

  ;; (let ((this-buffer-name (string-trim bufname))
  ;;        (this-buffer-mode (symbol-name (buffer-mode bufname))))
  ;;   (and
  ;;     (eq buffer-read-only t)
  ;;     (not (seq-filter
  ;;            (lambda (n) (string-prefix-p n this-buffer-mode))
  ;;            should-not-display-dark-background-modes))
  ;;     (not (derived-mode-p 'prog-mode)))))

(defun my-god-this-buffer-window-no-padding (bufname)
  "Check if BUFNAME window shoudn't have padding."
  (interactive)
  (let ((this-buffer-name (string-trim bufname))
         (this-buffer-mode (symbol-name (buffer-mode bufname))))
    (seq-filter
      (lambda (n) (string-prefix-p n this-buffer-mode))
      should-not-display-no-paddings-modes)
    ))

(setq my-god-mode-is-active-flag nil)

(defun refresh-current-mode ()
  "Refresh the current mode settings based on buffer type."
  (interactive)
  (when (my-god-this-is-dark-background-buffer (buffer-name))
      (set (make-local-variable 'face-remapping-alist)
           `((default :background ,darker-window-bg-color)
             (line-number :background ,darker-window-bg-color :foreground "#627d9d")
             (line-number-current-line :background ,darker-window-bg-color :foreground "#627d9d"))))
  (when (my-god-this-buffer-window-no-padding (buffer-name))
    (setq-local window-margins '(0 . 0)))
  (cond
   ((my-god-this-is-legendary-buffer (buffer-name))
    ;; (message "%s is legendary buffer" (buffer-name))
    (god-local-mode 0)
    (my-keys-minor-mode 0)
    (my-special-buffer-keys-minor-mode 0))
   ((my-god-this-is-special-buffer (buffer-name))
    ;; (message "%s is special buffer" (buffer-name))
    (god-local-mode 0)
    (my-keys-minor-mode 0)
    (my-special-buffer-keys-minor-mode 1))
   (t
    ;; (message "%s not a special buffer" (buffer-name))
    (god-local-mode 1) ;; start local mode
    (my-keys-minor-mode 1)
    (setq my-god-mode-is-active-flag t)
    (my-special-buffer-keys-minor-mode 0))))

(add-hook 'find-file-hook 'refresh-current-mode)

(defun my-quit-god-mode ()
  "Quit god mode."
  (interactive)
  (god-local-mode 0)
  (setq my-god-mode-is-active-flag nil))

(defun my-toggle-god-mode ()
  "Toggle god mode."
  (interactive)
  (if (bound-and-true-p god-local-mode)
      (my-quit-god-mode)
    (refresh-current-mode)))

(defun my-god-mode-with-switch-any-buffer (prev curr)
  "Handle god mode when switching buffers from PREV to CURR."
  (cl-assert (eq curr (current-buffer))) ;; Always t
  ;; (message "%S -> %S -> %S" prev curr (string-trim (buffer-name curr)))
  (refresh-current-mode))

(add-hook 'switch-buffer-functions #'my-god-mode-with-switch-any-buffer)

(defun my-god-below-newline-and-insert-mode ()
  (interactive)
  (end-of-line)
  (newline-and-indent)
  (my-quit-god-mode))

(defun my-god-above-newline-and-insert-mode ()
  (interactive)
  (beginning-of-line)
  (newline)
  (previous-line)
  (indent-for-tab-command)
  (my-quit-god-mode))

(defun my-god-mwin-end-and-insert-mode ()
  (interactive)
  (mwim-end-of-code-or-line)
  (my-quit-god-mode))

(defun my-god-mwin-beginning-and-insert-mode ()
  (interactive)
  (mwim-beginning-of-code-or-line)
  (my-quit-god-mode))

(defun my-god-char-forward-and-insert-mode ()
  (interactive)
  (forward-char)
  (my-quit-god-mode))

;; donot warnning, just wrap search
(defun isearch-repeat-forward+ ()
  (interactive)
  (unless isearch-forward
    (goto-char isearch-other-end))
  (isearch-repeat-forward)
  (unless isearch-success
    (isearch-repeat-forward))
  ;; (recenter)
  )

(defun isearch-repeat-backward+ ()
  (interactive)
  (when (and isearch-forward isearch-other-end)
    (goto-char isearch-other-end))
  (isearch-repeat-backward)
  (unless isearch-success
    (isearch-repeat-backward))
  ;; (recenter)
  )

(require 'god-mode-isearch)
(define-key isearch-mode-map (kbd "TAB") #'god-mode-isearch-activate)
(define-key god-mode-isearch-map (kbd "TAB") #'god-mode-isearch-disable)
;; RET to god, then RET to exit
;; (define-key isearch-mode-map (kbd "RET") #'god-mode-isearch-activate)
;; this variable make sure RET exit isearch-mode immediately

(define-key isearch-mode-map (kbd "RET") #'isearch-exit)
(define-key isearch-mode-map (kbd "C-l") #'recenter-top-bottom)

(define-key isearch-mode-map (kbd "C-s") 'isearch-repeat-forward+)
(define-key isearch-mode-map (kbd "C-r") 'isearch-repeat-backward+)
;; like vim
;; reset all other keys. then add our specific keys.
(set-char-table-range (nth 1 god-mode-isearch-map) t #'ignore)
(define-key god-mode-isearch-map (kbd "n") 'isearch-repeat-forward+)
(define-key god-mode-isearch-map (kbd "N") 'isearch-repeat-backward+)
(define-key god-mode-isearch-map (kbd "p") 'yank)
(define-key god-mode-isearch-map (kbd "u") 'undo)
(define-key god-mode-isearch-map (kbd "d") 'kill-whole-line)
(define-key god-mode-isearch-map (kbd "j") #'(lambda ()
                                               (interactive)
                                               (isearch-exit)
                                               (next-line)))
(define-key god-mode-isearch-map (kbd "k") #'(lambda ()
                                               (interactive)
                                               (isearch-exit)
                                               (previous-line)))
(define-key god-mode-isearch-map (kbd "h") #'(lambda ()
                                               (interactive)
                                               (isearch-exit)
                                               (my-forward-char-no-cross-line)))
(define-key god-mode-isearch-map (kbd "l") 'recenter-top-bottom)
(define-key god-mode-isearch-map (kbd "C-l") 'recenter-top-bottom)
(define-key god-mode-isearch-map (kbd ";") 'scroll-up-command)
(define-key god-mode-isearch-map (kbd "'") 'scroll-down-command)
(define-key god-mode-isearch-map (kbd "s") 'isearch-repeat-forward+)
(define-key god-mode-isearch-map (kbd "r") 'isearch-repeat-backward+)
(define-key god-mode-isearch-map (kbd "RET") #'isearch-exit)

(defun my-search-selection ()
  "search for selected text"
  (interactive)
  (if (region-active-p)
    (let ((selection (buffer-substring-no-properties (mark) (point)))
           (case-fold-search 'default))
      (message "search the marked region")
      (deactivate-mark)
      (isearch-mode t nil nil nil)
      ;; activate god-mode-isearch
      (god-mode-isearch-activate)
      (isearch-yank-string selection))
    (progn
      (isearch-forward-symbol-at-point)
      (god-mode-isearch-activate))))

(defun my-isearch-forward ()
  (interactive)
  (isearch-mode t nil nil nil)
  (god-mode-isearch-activate)
  (isearch-repeat-forward+))

(defun my-isearch-backward ()
  (interactive)
  (isearch-mode nil nil nil nil)
  (god-mode-isearch-activate)
  (isearch-repeat-backward+))

(defun my-god-mode-update-cursor-type ()
  (setq cursor-type (if (display-graphic-p) 'box 'box))
  (set-cursor-color (if (bound-and-true-p god-local-mode) "red" "red"))
  (blink-cursor-mode (if (bound-and-true-p god-local-mode) -1 -1))
  (sp--maybe-init)
  (if (bound-and-true-p god-local-mode)
    (progn
      ;; (set-face-attribute 'hl-line nil :background (face-background 'default))
      (set-face-background 'hl-line hl-line-bg-color)
      ;; reset
      (when (my-god-this-is-normal-editor-buffer (buffer-name))
        (if (my-god-should-enable-hi-line-mode) (hl-line-mode 1) (hl-line-mode 0))
        (when (my-god-should-enable-line-number-mode)
          (display-line-numbers-mode 1)
          ;; (set-face-foreground 'line-number-current-line "gray33")
           ;;;;  (set-face-attribute 'line-number-current-line nil
           ;;;;    :foreground (or (face-foreground 'line-number) 'unspecified)
           ;;;;    :background (or (face-background 'line-number) 'unspecified))
          )
        )
      ;; (when (display-graphic-p)
      ;;  (set-face-attribute 'window-divider nil :foreground window-divider-right-color)
      ;;  (set-face-attribute 'window-divider-last-pixel nil :foreground window-divider-right-color)
      ;;  (set-face-attribute 'window-divider-first-pixel nil :foreground "green")
      ;;  ;; (set-face-attribute 'mode-line nil          :background "#7AA2F7" :foreground "#262831" :overline "#374250"   :box nil) ;; draw a line above mode-line
      ;;  ;; (set-face-attribute 'mode-line-inactive nil :background "#262831" :foreground "#7AA2F7" :overline "#374250"  :box nil)
      ;;  ;; (set-face-attribute 'mode-line-buffer-id nil :distant-foreground "#262831" :foreground "#7AA2F7")
      ;;)
      ;; (unless (display-graphic-p)
      ;;   (set-face-attribute 'mode-line          nil :foreground "black" :background "#00AFFF")
      ;;   (set-face-attribute 'mode-line-inactive nil :foreground "#00AFFF" :background "black")
      ;;   )
      ;; (setq cursor-type 'bar)
      ;; (set-cursor-color "red")
      ;; (set-face-attribute 'mode-line nil :box '(:line-width 1 :color "gray" ))
      ;; (set-face-attribute 'mode-line nil :background "#38424B")
      ;; (set-face-foreground 'vertical-border "#353535")
      (set-face-attribute 'tab-bar-tab nil
                    :foreground "black"
                    :background "green"
                    :box '(:line-width (3 . 3) :color "green" :style flat-button)
                    )

      ;; (set-face-foreground 'vertical-border "#374250")
      )
    (progn
      ;; (set-face-attribute 'hl-line nil :background (face-background 'default))
      ;; (set-face-background 'hl-line hl-line-bg-color)
      (when (my-god-this-is-normal-editor-buffer (buffer-name))
        ;; (set-face-foreground 'vertical-border "#7fdc59")

        (set-face-attribute 'tab-bar-tab nil
                    :foreground "black"
                    :background "yellow"
                    :box '(:line-width (3 . 3) :color "yellow" :style flat-button)
                    )
        (when (my-god-should-enable-line-number-mode)
          (display-line-numbers-mode 1)
          ;; (set-face-foreground 'line-number-current-line "#7fdc59")
          ;;;;; (set-face-attribute 'line-number-current-line nil :foreground "black" :background "#7fdc59")
          )
        )
      ;; (when (display-graphic-p)
      ;;   (set-face-attribute 'window-divider nil :foreground window-divider-right-color)
      ;;   (set-face-attribute 'window-divider-last-pixel nil :foreground window-divider-right-color)
      ;;   (set-face-attribute 'window-divider-first-pixel nil :foreground "green")
      ;;   ;; (set-face-attribute 'mode-line nil          :background "#7fdc59" :foreground "black" :overline "green"   :box nil) ;; draw a line above mode-line
      ;;   ;; (set-face-attribute 'mode-line-inactive nil :background "#262831" :foreground "#7AA2F7" :overline "#374250"  :box nil)
      ;;   ;; (set-face-attribute 'mode-line-buffer-id nil :distant-foreground "#7AA2F7" :foreground "black")
      ;;   )
      ;; (unless (display-graphic-p)
      ;;   (set-face-attribute 'mode-line          nil :foreground "black" :background "cyan")
      ;;   (set-face-attribute 'mode-line-inactive nil :foreground "#00AFFF" :background "black")
      ;;   )
      ;; (setq cursor-type 'bar)
      ;; (set-cursor-color "red")
      ;; (set-face-attribute 'mode-line nil :box '(:line-width 1 :color "green" ))
      ;;(set-face-attribute 'mode-line nil :background "#38424B")
      ;; (set-face-foreground 'vertical-border window-divider-color)
      )
    ))

(add-hook 'god-mode-enabled-hook 'my-god-mode-update-cursor-type)
(add-hook 'god-mode-disabled-hook 'my-god-mode-update-cursor-type)

(provide 'init-god)
