;; -*- lexical-binding: t -*-
;;; init-eww.el --- Eww configuration

;; eww / shr 默认正文用 variable-pitch（"Sans Serif"），代码用 fixed-pitch（"Monospace"），
;; 都不是 IBM Plex，看着很怪。关掉 shr-use-fonts 后统一用 default face（IBM Plex Mono）。

;;; Code:

;; Package variables, declared for the byte compiler.
(defvar eww-mode-map)

(use-package shr
  :ensure nil
  :defer t
  :config
  (setq shr-use-fonts nil)
  ;; 不显示图片（HyperSpec 里的图标/导航图片），M-I (eww-toggle-images) 可临时打开
  (setq shr-inhibit-images t)
  ;; HyperSpec 把顶部导航图片放在 <H1> 里，图片关掉后替代文字用 shr-h1 (1.3 倍) 显示太大
  (set-face-attribute 'shr-h1 nil :height 1.0)
  ;; Limit line length.
  (setq shr-width 88)
  ;; Indent <blockquote> by 2 columns. `my-eww-indent-sections' uses it.
  (setq shr-block-indentation-width 2)
  ;; Make section headings easy to find.
  (set-face-attribute 'shr-h2 nil :inherit 'font-lock-keyword-face
                      :underline '(:color "gray30" :style line)))

(defvar my-hyperspec-cache-dir)
(defvar my-hyperspec-root)

(defun my-eww-indent-pre (node first)
  "Return the pre NODE with its text indented like a blockquote.
SHR does not indent pre blocks.  If FIRST is non-nil, NODE starts the
blockquote.  SHR then indents its first line.  Do not indent it again."
  (let ((pad (make-string shr-block-indentation-width ?\s)))
    (cl-labels ((indent (x)
                  (cond ((stringp x)
                         (concat (unless (prog1 first (setq first nil)) pad)
                                 (replace-regexp-in-string "\n" (concat "\n" pad) x t t)))
                        ((consp x) (cons (car x) (cons (cadr x) (mapcar #'indent (cddr x)))))
                        (t x))))
      (indent node))))

(defun my-eww-indent-sections (document)
  "Return DOCUMENT with the nodes after each h2 wrapped in a blockquote.
A section ends at the next h2 or at an hr."
  (when-let* ((body (car (dom-by-tag document 'body))))
    (let (result group in-section)
      (cl-flet ((flush ()
                  (when group
                    (push `(blockquote nil ,@(nreverse group)) result)
                    (setq group nil))))
        (dolist (node (dom-children body))
          (pcase (and (consp node) (dom-tag node))
            ('h2 (flush)
                 (push node result)
                 (setq in-section t))
            ('hr (flush)
                 (push node result)
                 (setq in-section nil))
            (_ (push (if (and in-section (consp node) (eq (dom-tag node) 'pre))
                         (my-eww-indent-pre
                          node
                          (cl-every (lambda (x)
                                      (and (stringp x) (string-blank-p x)))
                                    group))
                       node)
                     (if in-section group result)))))
        (flush))
      (setcdr (cdr body) (nreverse result))))
  document)

;; Do not advise `eww-document-base'.  Native-compiled eww calls it directly.
(define-advice shr-insert-document (:around (fn document) my-hyperspec)
  "Indent the sections and highlight the code of the local HyperSpec pages."
  (let ((url (dom-attr (car (dom-by-tag document 'base)) 'href)))
    (if (and url
             (boundp 'my-hyperspec-cache-dir)
             (string-prefix-p (concat "file://" (expand-file-name my-hyperspec-cache-dir))
                              url))
        (let ((shr-external-rendering-functions
               (cons '(pre . my-eww-render-pre) shr-external-rendering-functions)))
          (funcall fn (my-eww-indent-sections document)))
      (funcall fn document))))

(defconst my-eww--loop-keyword-regexp
  (concat "\\_<"
          (regexp-opt '("named" "initially" "finally" "for" "as" "with" "do" "doing"
                        "return" "collect" "collecting" "append" "appending"
                        "nconc" "nconcing" "count" "counting" "sum" "summing"
                        "maximize" "maximizing" "minimize" "minimizing" "into"
                        "while" "until" "repeat" "always" "never" "thereis"
                        "if" "when" "unless" "else" "end" "and" "in" "on" "by"
                        "from" "upfrom" "downfrom" "to" "upto" "downto" "below"
                        "above" "across" "being" "the" "each" "of" "of-type"
                        "hash-key" "hash-keys" "hash-value" "hash-values" "using"
                        "symbol" "symbols" "present-symbol" "present-symbols"
                        "external-symbol" "external-symbols" "=" "then"))
          "\\_>")
  "Regexp that matches a LOOP keyword.")

(defun my-eww--match-loop-keyword (limit)
  "Find the next LOOP keyword before LIMIT.
Match a keyword only when it is a direct element of a (loop ...) form."
  (let ((case-fold-search t)
        found)
    (while (and (not found)
                (re-search-forward my-eww--loop-keyword-regexp limit t))
      (let ((open (save-excursion
                    (save-match-data (nth 1 (syntax-ppss (match-beginning 0)))))))
        (when (and open
                   (save-excursion
                     (goto-char (1+ open))
                     (save-match-data (looking-at-p "loop\\_>"))))
          (setq found t))))
    found))

(defconst my-eww--cl-symbol-kind-faces
  '(("f" . font-lock-function-call-face)
    ("a" . font-lock-function-call-face)
    ("m" . font-lock-keyword-face)
    ("s" . font-lock-keyword-face)
    ("v" . font-lock-variable-name-face)
    ("t" . font-lock-type-face)
    ("e" . font-lock-type-face))
  "Face for each HyperSpec page prefix.  Map_Sym.txt gives the page of a symbol.")

(defvar my-eww--cl-symbol-faces nil
  "Hash table from an upcased CL symbol name to its face.")

(defun my-eww--cl-symbol-faces ()
  "Return the CL symbol face table.  Read Map_Sym.txt on the first call."
  (or my-eww--cl-symbol-faces
      (let ((table (make-hash-table :test #'equal))
            (file (and (boundp 'my-hyperspec-root)
                       (expand-file-name "Data/Map_Sym.txt" my-hyperspec-root))))
        (when (and file (file-readable-p file))
          (with-temp-buffer
            (insert-file-contents file)
            ;; Each symbol line is followed by its page, e.g. "../Body/f_car_c.htm".
            (while (re-search-forward "^\\(.+\\)\n\\.\\./Body/\\([a-z]\\)_" nil t)
              (when-let* ((face (cdr (assoc (match-string 2) my-eww--cl-symbol-kind-faces))))
                (puthash (match-string 1) face table)))))
        (setq my-eww--cl-symbol-faces table))))

(defvar my-eww--cl-symbol-face nil
  "Face of the last CL symbol that `my-eww--match-cl-symbol' found.")

(defun my-eww--match-cl-symbol (limit)
  "Find the next standard CL symbol before LIMIT."
  (let ((table (my-eww--cl-symbol-faces))
        found)
    (while (and (not found)
                (re-search-forward "\\_<\\(?:\\sw\\|\\s_\\)+\\_>" limit t))
      (setq found (gethash (upcase (match-string 0)) table)))
    (setq my-eww--cl-symbol-face found)
    (and found t)))

(defconst my-eww--lisp-extra-keywords
  '((my-eww--match-loop-keyword . 'font-lock-builtin-face)
    (my-eww--match-cl-symbol (0 my-eww--cl-symbol-face)))
  "Extra font-lock rules for the HyperSpec code examples.")

(defun my-eww-fontify-lisp (start end)
  "Highlight the text from START to END as Lisp code.
Use the same font-lock modes as the Lisp source buffers."
  (let ((text (buffer-substring-no-properties start end)))
    (with-temp-buffer
      (insert text)
      (delay-mode-hooks (lisp-mode))
      (font-lock-set-defaults)
      (font-lock-add-keywords nil my-eww--lisp-extra-keywords 'append)
      (when (fboundp 'highlight-numbers-mode) (highlight-numbers-mode))
      (when (fboundp 'rainbow-delimiters-mode) (rainbow-delimiters-mode))
      (font-lock-ensure)
      (let ((pos (point-min)))
        (while (< pos (point-max))
          (let ((next (next-single-property-change pos 'face nil (point-max)))
                (face (get-text-property pos 'face)))
            (when face
              (with-current-buffer (marker-buffer start)
                (add-face-text-property (+ start (- pos (point-min)))
                                        (+ start (- next (point-min)))
                                        face)))
            (setq pos next)))))))

(defun my-eww-render-pre (dom)
  "Render the pre DOM and highlight it as Lisp code.
The `shr-insert-document' advice adds this function to
`shr-external-rendering-functions'."
  (let ((start (point-marker)))
    (shr-tag-pre dom)
    (my-eww-fontify-lisp start (point))))

;; eww buffer 不是 find-file 打开的，find-file-hook 不会触发，这里补上；
;; eww-mode 在 my-special-buffer-modes 里，所以会关掉 god mode、开启 special buffer keys
(add-hook 'eww-mode-hook #'my-init-god-mode-for-new-buffer)

(with-eval-after-load 'eww
  (keymap-set eww-mode-map "H" #'eww-back-url)
  (keymap-set eww-mode-map "L" #'eww-forward-url))


(provide 'init-eww)

;;; init-eww.el ends here
