;; -*- lexical-binding: t -*-
;;; init-god.el --- God mode configuration

;;; Commentary:
;;
;;  God mode, buffer classes and the per-buffer mode switching.
;;
;;  Buffer classes:
;;    normal     god-mode and `my-keys-minor-mode' on.
;;    special    god-mode off, `my-special-buffer-keys-minor-mode' on.
;;    legendary  god-mode and both key modes off.
;;
;;  Layout:
;;    1. Settings.  2. Buffer class lists.  3. Classification.
;;    4. Window margins and visuals.  5. Mode switching.
;;    6. Insert-mode commands.  7. Isearch.  8. Tab bar and cursor.
;;    9. Hooks.
;;

;;; Code:

(require 'god-mode)

(defvar my-darker-window-bg-color)
(defvar my-hl-line-bg-color)
(declare-function sp--maybe-init "smartparens")
(declare-function mwim-end-of-code-or-line "mwim")
(declare-function mwim-beginning-of-code-or-line "mwim")


;;; Settings

(setq god-exempt-major-modes nil
      god-exempt-predicates nil
      god-mode-alist '((nil . "C-") ("r" . "M-") ("R" . "C-M-")))

;; donot warnning, just wrap search
(setq isearch-wrap-pause 'no-ding
      isearch-repeat-on-direction-change t)

(blink-cursor-mode -1)


;;; Buffer class lists

;; my-special-buffers are not affected by god-mode bindings, but affected by my-special-buffer-keys-minor-mode-map
(defvar my-special-buffer-modes
  (list
   "dired-mode"
   "ibuffer-mode"
   "special-mode"
   "native-comp-limple-mode"
   "ivy-occur-mode"
   "image-mode"
   "eww-mode"))

(defvar my-special-buffers (list
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
                         "*Ilist"
                         "*NeoTree*"))

;; my-legendary-buffers are not affected by god-mode AND my-special-buffer-keys-minor-mode-map
(defvar my-legendary-buffers (list
                           "*this-buffer-is-left-alone-without-god-mode-at-all"
                           "*Minibuf"
                           "*Compile"
                           "*EGLOT"
                           "*terminal*"
                           "*eat"
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

(defvar my-legendary-modes (list
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

(defvar my-should-not-display-dark-background-modes (list
                                                  "dired-mode"
                                                  "eat-mode"
                                                  "eldoc-box-mode"
                                                  "xwidget-webkit-mode"
                                                  "minibuffer-mode"
                                                  "dashboard-mode"))

(defvar my-should-not-display-no-paddings-modes (list
                                              "xwidget-webkit-mode"))

(defun my-change-buffer-name-from-special-to-legendary (buffer-name)
  "Move BUFFER-NAME from `my-special-buffers' to `my-legendary-buffers'."
  (setq my-special-buffers (remove buffer-name my-special-buffers))
  (add-to-list 'my-legendary-buffers buffer-name))

(defun my-change-buffer-name-from-legendary-to-special (buffer-name)
  "Move BUFFER-NAME from `my-legendary-buffers' to `my-special-buffers'."
  (setq my-legendary-buffers (remove buffer-name my-legendary-buffers))
  (add-to-list 'my-special-buffers buffer-name))

(defun my-add-to-legendary-buffers (buffer-names)
  "Add BUFFER-NAMES (a string or a list) to `my-legendary-buffers'."
  (dolist (element (if (listp buffer-names) buffer-names (list buffer-names)))
    (add-to-list 'my-legendary-buffers element)))

(defun my-remove-from-legendary-buffers (buffer-names)
  "Remove BUFFER-NAMES (a string or a list) from `my-legendary-buffers'."
  (dolist (element (if (listp buffer-names) buffer-names (list buffer-names)))
    (setq my-legendary-buffers (remove element my-legendary-buffers))))


;;; Classification

(defun my-god--buffer-mode-name (bufname)
  "Return the major mode name of buffer BUFNAME as a string."
  (symbol-name (buffer-local-value 'major-mode (get-buffer bufname))))

(defun my-god--prefix-match-p (prefixes str)
  "Return non-nil if STR starts with any of PREFIXES."
  (seq-some (lambda (n) (string-prefix-p n str)) prefixes))

(defun my-god-this-is-special-buffer (bufname)
  "Check if BUFNAME is a special buffer."
  (or (my-god--prefix-match-p my-special-buffers (string-trim bufname))
      (my-god--prefix-match-p my-special-buffer-modes (my-god--buffer-mode-name bufname))))

(defun my-god-this-is-legendary-buffer (bufname)
  "Check if BUFNAME is a legendary buffer."
  (or (my-god--prefix-match-p my-legendary-buffers (string-trim bufname))
      (my-god--prefix-match-p my-legendary-modes (my-god--buffer-mode-name bufname))))

(defun my-god-this-is-normal-editor-buffer (bufname)
  "Check if BUFNAME is a normal editor buffer."
  (not
   (or (my-god-this-is-special-buffer bufname)
       (my-god-this-is-legendary-buffer bufname))))

(defun my-god-should-enable-hi-line-mode ()
  "Check if hi-line mode should be enabled."
  (not (bound-and-true-p smerge-mode)))

(defun my-god-should-enable-line-number-mode ()
  "Check if line number mode should be enabled."
  (not (derived-mode-p 'vterm-mode)))

(defun my-god-this-is-dark-background-buffer (bufname)
  "Check if BUFNAME should have dark background."
  (not
   (or
    ;; Check if buffer name matches (for eldoc-box and similar)
    (string-prefix-p "*eldoc-box*" (string-trim bufname))
    ;; Check if major-mode matches
    (my-god--prefix-match-p my-should-not-display-dark-background-modes
                            (my-god--buffer-mode-name bufname)))))

;; (let ((this-buffer-name (string-trim bufname))
;;        (this-buffer-mode (symbol-name (my-buffer-mode bufname))))
;;   (and
;;     (eq buffer-read-only t)
;;     (not (seq-filter
;;            (lambda (n) (string-prefix-p n this-buffer-mode))
;;            my-should-not-display-dark-background-modes))
;;     (not (derived-mode-p 'prog-mode)))))

(defun my-god-this-buffer-window-no-padding (bufname)
  "Check if BUFNAME window shoudn't have padding."
  (my-god--prefix-match-p my-should-not-display-no-paddings-modes
                          (my-god--buffer-mode-name bufname)))


;;; Window margins and visuals

(defvar-local my-window-margins nil
  "Buffer-local (LEFT . RIGHT) margins overriding `my-set-margins-all-windows'.")

(defun my-set-margins-all-windows ()
  "给所有窗口设置边距，排除指定的 major mode 以及设置了 `my-window-margins' 的 buffer"
  (dolist (window (window-list))
    (with-current-buffer (window-buffer window)
      (let ((margins (cond (my-window-margins)
                           ((member (symbol-name major-mode) my-should-not-display-no-paddings-modes)
                            '(0 . 0))   ; 排除的模式设置为0
                           (t '(1 . 1)))) ; 其他模式设置边距
            (current (window-margins window)))
        (unless (and (eql (or (car current) 0) (car margins))
                     (eql (or (cdr current) 0) (cdr margins)))
          (set-window-margins window (car margins) (cdr margins)))))))

(defun my-refresh-current-mode-visuals ()
  "Apply visual settings for the current buffer (background, margins)."
  (when (my-god-this-is-dark-background-buffer (buffer-name))
    (make-local-variable 'face-remapping-alist)
    (cl-flet ((set-remap (face props)
                (setq face-remapping-alist
                      (cons (cons face props)
                            (assq-delete-all face face-remapping-alist)))))
      (set-remap 'default `(:background ,my-darker-window-bg-color))
      (set-remap 'line-number `(:background ,my-darker-window-bg-color :foreground "#627d9d"))
      (set-remap 'line-number-current-line `(:background ,my-darker-window-bg-color :foreground "#627d9d"))))
  (when (and (my-god-this-buffer-window-no-padding (buffer-name))
             (not my-window-margins))
    (setq my-window-margins '(0 . 0))
    (my-set-margins-all-windows)))


;;; Mode switching

(defvar-local my-god-mode-is-active-flag nil
  "Non-nil if god-mode was explicitly enabled in this buffer.")

(defun my-god--setup-legendary-or-special-buffer ()
  "Set modes for legendary/special buffers; return nil for normal buffers."
  (cond
   ((my-god-this-is-legendary-buffer (buffer-name))
    (god-local-mode 0)
    (my-keys-minor-mode 0)
    (my-special-buffer-keys-minor-mode 0)
    t)
   ((my-god-this-is-special-buffer (buffer-name))
    (god-local-mode 0)
    (my-keys-minor-mode 0)
    (my-special-buffer-keys-minor-mode 1)
    t)))

(defun my-refresh-current-mode ()
  "Refresh the current mode settings based on buffer type.
When switching to an existing buffer, respect its prior god-mode state."
  (interactive)
  (my-refresh-current-mode-visuals)
  (cond
   ((my-god--setup-legendary-or-special-buffer))
   (t
    ;; Restore the buffer's own god-mode state; don't override if user disabled it.
    (if my-god-mode-is-active-flag
        (progn
          (god-local-mode 1)
          (my-keys-minor-mode 1)
          (my-special-buffer-keys-minor-mode 0))
      ;; Flag is nil: only enable if god-local-mode isn't already explicitly off.
      ;; This branch is hit on buffer-switch; new files are handled by init below.
      (my-keys-minor-mode (if (bound-and-true-p god-local-mode) 1 0))
      (my-special-buffer-keys-minor-mode 0))))
  ;; Always sync tab bar color to current buffer's god-mode state.
  (my-god-mode-update-cursor-type))

(defun my-init-god-mode-for-new-buffer ()
  "Enable god-mode for a newly opened file buffer (find-file-hook)."
  (my-refresh-current-mode-visuals)
  (cond
   ((my-god--setup-legendary-or-special-buffer))
   (t
    (god-local-mode 1)
    (my-keys-minor-mode 1)
    (setq my-god-mode-is-active-flag t)
    (my-special-buffer-keys-minor-mode 0))))

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
    (god-local-mode 1)
    (my-keys-minor-mode 1)
    (setq my-god-mode-is-active-flag t)
    (my-special-buffer-keys-minor-mode 0)))

(defun my-god-mode-with-switch-any-buffer (_prev curr)
  "Handle god mode when switching buffers from PREV to CURR."
  (cl-assert (eq curr (current-buffer))) ;; Always t
  (my-refresh-current-mode))


;;; Insert-mode commands

(defun my-god-below-newline-and-insert-mode ()
  "Open a new line below and quit god mode."
  (interactive)
  (end-of-line)
  (newline-and-indent)
  (my-quit-god-mode))

(defun my-god-above-newline-and-insert-mode ()
  "Open a new line above and quit god mode."
  (interactive)
  (beginning-of-line)
  (newline)
  (forward-line -1)
  (indent-for-tab-command)
  (my-quit-god-mode))

(defun my-god-mwin-end-and-insert-mode ()
  "Go to the end of code or line and quit god mode."
  (interactive)
  (mwim-end-of-code-or-line)
  (my-quit-god-mode))

(defun my-god-mwin-beginning-and-insert-mode ()
  "Go to the beginning of code or line and quit god mode."
  (interactive)
  (mwim-beginning-of-code-or-line)
  (my-quit-god-mode))

(defun my-god-char-forward-and-insert-mode ()
  "Move forward one char and quit god mode."
  (interactive)
  (forward-char)
  (my-quit-god-mode))


;;; Isearch

(defun my-isearch-repeat-forward ()
  "Repeat isearch forward."
  (interactive)
  (isearch-repeat-forward))

(defun my-isearch-repeat-backward ()
  "Repeat isearch backward."
  (interactive)
  (isearch-repeat-backward))

(defun my-god-isearch-exit-next-line ()
  "Exit isearch and move to the next line."
  (interactive)
  (isearch-exit)
  (line-move 1))

(defun my-god-isearch-exit-previous-line ()
  "Exit isearch and move to the previous line."
  (interactive)
  (isearch-exit)
  (line-move -1))

(defun my-god-isearch-exit-forward-char ()
  "Exit isearch and move forward one char on the line."
  (interactive)
  (isearch-exit)
  (my-forward-char-no-cross-line))

(defun my-search-selection ()
  "search for selected text"
  (interactive)
  (if (region-active-p)
      (let ((isearch-forward-thing-at-point '(region))
            (case-fold-search 'default))
        (message "search the marked region")
        (isearch-forward-thing-at-point)
        ;; activate god-mode-isearch
        (god-mode-isearch-activate)
        ;; 跳到下一个匹配（跳过选区本身）
        (isearch-repeat-forward))
    (isearch-forward-symbol-at-point)
    (god-mode-isearch-activate)))

(defun my-isearch-forward ()
  "Start isearch forward in god-mode isearch."
  (interactive)
  (isearch-mode t nil nil nil)
  (god-mode-isearch-activate)
  (my-isearch-repeat-forward))

(defun my-isearch-backward ()
  "Start isearch backward in god-mode isearch."
  (interactive)
  (isearch-mode nil nil nil nil)
  (god-mode-isearch-activate)
  (my-isearch-repeat-backward))

(require 'god-mode-isearch)
(keymap-set isearch-mode-map "TAB" #'god-mode-isearch-activate)
(keymap-set god-mode-isearch-map "TAB" #'god-mode-isearch-disable)
;; RET to god, then RET to exit
;; (define-key isearch-mode-map (kbd "RET") #'god-mode-isearch-activate)
;; this variable make sure RET exit isearch-mode immediately

(keymap-set isearch-mode-map "RET" #'isearch-exit)
(keymap-set isearch-mode-map "C-l" #'recenter-top-bottom)

(keymap-set isearch-mode-map "C-s" #'my-isearch-repeat-forward)
(keymap-set isearch-mode-map "C-r" #'my-isearch-repeat-backward)

;; like vim
;; reset all other keys. then add our specific keys.
;; (char-table range t 覆盖所有字符；"<t>" 默认绑定还会吞掉非字符事件，不等价)
(set-char-table-range (nth 1 god-mode-isearch-map) t #'ignore)
(keymap-set god-mode-isearch-map "n" #'my-isearch-repeat-forward)
(keymap-set god-mode-isearch-map "N" #'my-isearch-repeat-backward)
(keymap-set god-mode-isearch-map "p" #'yank)
(keymap-set god-mode-isearch-map "u" #'undo)
(keymap-set god-mode-isearch-map "d" #'kill-whole-line)
(keymap-set god-mode-isearch-map "j" #'my-god-isearch-exit-next-line)
(keymap-set god-mode-isearch-map "k" #'my-god-isearch-exit-previous-line)
(keymap-set god-mode-isearch-map "h" #'my-god-isearch-exit-forward-char)
(keymap-set god-mode-isearch-map "l" #'recenter-top-bottom)
(keymap-set god-mode-isearch-map "C-l" #'recenter-top-bottom)
(keymap-set god-mode-isearch-map ";" #'scroll-up-command)
(keymap-set god-mode-isearch-map "'" #'scroll-down-command)
(keymap-set god-mode-isearch-map "s" #'my-isearch-repeat-forward)
(keymap-set god-mode-isearch-map "r" #'my-isearch-repeat-backward)
(keymap-set god-mode-isearch-map "RET" #'isearch-exit)


;;; Tab bar and cursor

(defvar my-god--tab-bar-tab-state nil
  "Last state (`god' or `insert') applied to the `tab-bar-tab' face.")

(defun my-god--set-tab-bar-tab-face (state color)
  "Paint the `tab-bar-tab' face with COLOR for STATE, only when STATE changes."
  (unless (eq state my-god--tab-bar-tab-state)
    (setq my-god--tab-bar-tab-state state)
    (set-face-attribute 'tab-bar-tab nil
                        :foreground "black"
                        :background color
                        :box `(:line-width (1 . 2) :color ,color :style flat-button))))

(defun my-god-mode-update-cursor-type ()
  "Update cursor, hl-line, line numbers and tab color for the god-mode state."
  (setq cursor-type 'box)
  (set-cursor-color "red")
  (sp--maybe-init)
  (if (bound-and-true-p god-local-mode)
      (progn
        (set-face-background 'hl-line my-hl-line-bg-color)
        (when (my-god-this-is-normal-editor-buffer (buffer-name))
          (if (my-god-should-enable-hi-line-mode) (hl-line-mode 1) (hl-line-mode 0))
          (when (my-god-should-enable-line-number-mode)
            (display-line-numbers-mode 1)))
        (my-god--set-tab-bar-tab-face 'god "#199DFF"))
    (when (my-god-this-is-normal-editor-buffer (buffer-name))
      (my-god--set-tab-bar-tab-face 'insert "yellow")
      (when (my-god-should-enable-line-number-mode)
        (display-line-numbers-mode 1)))))

;; Old face experiments, moved out of `my-god-mode-update-cursor-type'.
;;
;; God-mode branch:
;; (set-face-attribute 'hl-line nil :background (face-background 'default))
;; ;; reset
;; (set-face-foreground 'line-number-current-line "gray33")
;;;;  (set-face-attribute 'line-number-current-line nil
;;;;    :foreground (or (face-foreground 'line-number) 'unspecified)
;;;;    :background (or (face-background 'line-number) 'unspecified))
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
;; (set-face-foreground 'vertical-border "#374250")
;;
;; Insert branch:
;; (set-face-attribute 'hl-line nil :background (face-background 'default))
;; (set-face-background 'hl-line my-hl-line-bg-color)
;; (set-face-foreground 'vertical-border "#7fdc59")
;; (set-face-foreground 'line-number-current-line "#7fdc59")
;;;;; (set-face-attribute 'line-number-current-line nil :foreground "black" :background "#7fdc59")
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
;; (set-face-foreground 'vertical-border my-window-divider-color)


;;; Hooks

;; 在窗口配置改变时自动设置边距
(add-hook 'window-configuration-change-hook #'my-set-margins-all-windows)
(add-hook 'find-file-hook #'my-init-god-mode-for-new-buffer)
(add-hook 'switch-buffer-functions #'my-god-mode-with-switch-any-buffer)
(add-hook 'god-mode-enabled-hook #'my-god-mode-update-cursor-type)
(add-hook 'god-mode-disabled-hook #'my-god-mode-update-cursor-type)

;; Old names, so M-x with the old name still works.
(define-obsolete-function-alias 'isearch-repeat-backward+ #'my-isearch-repeat-backward "2026-10-27")
(define-obsolete-function-alias 'isearch-repeat-forward+ #'my-isearch-repeat-forward "2026-10-27")
(define-obsolete-function-alias 'refresh-current-mode #'my-refresh-current-mode "2026-10-27")

(provide 'init-god)

;;; init-god.el ends here
