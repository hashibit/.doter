;; -*- lexical-binding: t -*-
;;; my-text-boxes.el --- Text formatting and box drawing helpers

;;; Commentary:
;;
;;  String splitting, XML/JSON/Elisp formatting, and commands that draw
;;  a box around the region.
;;

;;; Code:

(require 'cl-lib)


(defun my-util-split-long-line-to-sub-lines (long-line wrap-width)
  "Split LONG-LINE into sub-lines with WRAP-WIDTH."
  (let ((total-len (string-width long-line))
        (idx 0)
        (collected ()))
    (while (> (- total-len idx) wrap-width)
      (push (substring long-line idx (+ idx wrap-width)) collected)
      (setq idx (+ idx wrap-width)))
    (when (< idx total-len)
      (push (substring long-line idx total-len) collected))
    (reverse collected)))

;; (message "%s" (my-util-split-long-line-to-sub-lines "It is useful to include newlines" 4))
;; (string-width "It is useful to include newlines")

(defun my-util-seperate-string (line max-length)
  "Separate LINE into chunks of MAX-LENGTH."
  (let ((remains line)
        (result-lines ()))
    (while (> (length remains) max-length)
      (push (substring remains 0 max-length) result-lines)
      (setq remains (substring remains max-length nil)))
    ;; last one
    (push remains result-lines)
    (reverse result-lines)))

(defun bf-pretty-print-xml-region (begin end)
  "Pretty format XML markup in region. You need to have nxml-mode
    http://www.emacswiki.org/cgi-bin/wiki/NxmlMode installed to do
    this.  The function inserts linebreaks to separate tags that have
    nothing but whitespace between them.  It then indents the markup
    by using nxml's indentation rules."
  (interactive "r")
  (save-excursion
    (nxml-mode)
    (goto-char begin)
    (while (search-forward-regexp "\>[ \\t ]*\<" nil t)
      (backward-char)
      (insert "\n")
      (setq end (1+ end)))
    (indent-region begin end))
  (message "Ah, much better!"))

(defun json-to-single-line (beg end)
  "Collapse prettified json in region between BEG and END to a single line"
  (interactive "r")
  (if (use-region-p)
      (json-pretty-print beg end t)
    (user-error "This function operates on a region")))

(defun my-pp-region (beg end)
  "Use `pp' to format the selected Elisp code, then indent and untabify."
  (interactive "r")
  (let
      ((str (buffer-substring-no-properties beg end))
       insert-start
       insert-end)
    (save-excursion
      (delete-region beg end) (setq insert-start (point))
      (condition-case err
          (let ((sexp (read str))) (insert (pp-to-string sexp)))
        (error (insert str)
               (user-error "Failed to parse Elisp: %s"
                           (error-message-string err))))
      (setq insert-end (point))
      (indent-region insert-start insert-end)
      (untabify insert-start insert-end))))

(defun my-wrap-in-line-box (start end)
  "用 face 属性画一个矩形框，避开 line-spacing 断裂。
选区会自动扩展到完整的行。"
  (interactive "r")
  (save-excursion
    (goto-char start)
    (setq start (line-beginning-position))
    (goto-char end)
    (setq end (line-end-position)))
  (let* ((lines (split-string (buffer-substring-no-properties start end) "\n"))
         (width (apply #'max (mapcar #'string-width lines)))
         (bg "#2a2a2a")
         (fg "#888888")
         (last (1- (length lines))))
    (delete-region start end)
    (cl-loop for line in lines
             for i from 0
             do (let ((p (point)))
                  (insert " " line
                          (make-string (- width (string-width line)) ?\s)
                          " ")
                  (let ((ov (make-overlay p (point))))
                    (overlay-put ov 'priority -50)
                    (overlay-put ov 'face
                                 `(:background ,bg
                                               :box (:line-width (1 . 0) :color ,fg)
                                               ,@(and (= i 0)    `(:overline ,fg))
                                               ,@(and (= i last) `(:underline (:color ,fg :position 0)))))))
             unless (= i last) do (insert "\n"))))


(defun my-wrap-in-bg-gray-box (start end &optional label)
  "用背景色块包裹选中区域，背景填充到最长行宽度形成矩形。"
  (interactive "r\ns输入顶部标签(可留空): ")
  (let* ((text (buffer-substring-no-properties start end))
         (lines (split-string text "\n"))
         (max-width (apply #'max (mapcar #'string-width lines)))
         (padded-text
          (mapconcat
           (lambda (line)
             (let ((pad (- max-width (string-width line))))
               (concat line (make-string pad ?\s))))
           lines
           "\n")))
    (delete-region start end)
    (let ((_content-start (point)))
      (when (and label (not (string-empty-p label)))
        (let* ((label-pad (max 0 (- max-width (string-width label))))
               (label-line (concat label (make-string label-pad ?\s) "\n"))
               (label-start (point)))
          (insert label-line)
          (let ((ov (make-overlay label-start (point))))
            (overlay-put ov 'face '(:background "#3a3a3a" :weight bold)))))
      (let ((body-start (point)))
        (insert padded-text)
        (let ((ov (make-overlay body-start (point))))
          (overlay-put ov 'face '(:background "#2a2a2a"))
          (overlay-put ov 'after-string
                       (propertize " " 'face '(:background "#2a2a2a"))))))))


(defun my-wrap-in-ascii-box (start end &optional label)
  "严格使用标准 Unicode Box Drawing 字符将文本包裹进对齐方框。"
  (interactive "r\ns输入顶部标签(可留空): ")
  (let* ((text (buffer-substring-no-properties start end))
         (lines (split-string text "\n"))
         ;; 1. 动态计算文字最大宽度（处理中文字符占用 2 个单位宽度的情况）
         (max-width (apply #'max (mapcar #'string-width lines)))
         (label-len (if (and label (not (string-empty-p label))) (string-width label) 0))
         (content-width (max max-width (if (> label-len 0) (+ label-len 2) 10)))
         (box-width (+ content-width 2))

         ;; 2. 严格使用标准 Box Drawing 字符拼接顶部
         (top-border (if (> label-len 0)
                         (let* ((dash-count (- box-width label-len 2))
                                (left-dash (make-string (/ dash-count 2) #x2500))
                                (right-dash (make-string (- dash-count (/ dash-count 2)) #x2500)))
                           (concat (string #x250C) left-dash label right-dash (string #x2510) "\n"))
                       (concat (string #x250C) (make-string box-width #x2500) (string #x2510) "\n")))

         ;; 底部边框
         (bottom-border (concat (string #x2514) (make-string box-width #x2500) (string #x2518)))
         (resulting-text ""))

    ;; 3. 逐行用标准垂直线和空格对齐填充
    (dolist (line lines)
      (let* ((line-len (string-width line))
             (padding-amount (- content-width line-len))
             (padding (make-string padding-amount ?\s)))
        (setq resulting-text
              (concat resulting-text (string #x2502) " " line padding " " (string #x2502) "\n"))))

    ;; 4. 替换文本
    (delete-region start end)
    (insert top-border resulting-text bottom-border)))


;; Old names, so M-x my/wrap-in-... still works.
(define-obsolete-function-alias 'my/wrap-in-line-box #'my-wrap-in-line-box "2026-10-27")
(define-obsolete-function-alias 'my/wrap-in-bg-gray-box #'my-wrap-in-bg-gray-box "2026-10-27")
(define-obsolete-function-alias 'my/wrap-in-ascii-box #'my-wrap-in-ascii-box "2026-10-27")

(provide 'my-text-boxes)

;;; my-text-boxes.el ends here
