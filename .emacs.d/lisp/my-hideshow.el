;; -*- lexical-binding: t -*-
;;; my-hideshow.el --- Code folding commands on top of hideshow

(require 'cl-lib)
(declare-function hs-toggle-all "hideshow")
(declare-function hs-toggle-hiding "hideshow")
(declare-function hs-hide-all "hideshow")
(declare-function hs-show-all "hideshow")
(declare-function hs-hide-level "hideshow")


(defun my-hs-is-there-hidden-code-p ()
  "精确检测：是否有代码因hideshow被隐藏？"
  (cl-some
   (lambda (ov)
     (eq 'code (overlay-get ov 'hs)))
   (overlays-in (point-min) (point-max))))


(defun my-hs-toggle-level ()
  "可靠切换代码折叠状态（无视hideshow内部状态缺陷）"
  (interactive)
  (if (my-hs-is-there-hidden-code-p)
      (progn
        (message "展开所有代码...")
        (hs-show-all))
    (progn
      (message "折叠层级1代码...")
      (hs-hide-level 1))))


(defun my-hs-toggle-all ()
  "If anything isn't hidden, run `hs-hide-all', else run `hs-show-all'."
  (interactive)
  (hs-minor-mode 1)
  (if (derived-mode-p 'c++-mode 'c++-ts-mode)
      ;; Fold one level inside the top-level namespace instead of the
      ;; namespace itself.
      (let ((starting-ov-count (length (overlays-in (point-min) (point-max)))))
        (save-excursion
          (goto-char (point-min))
          (when (re-search-forward "namespace.*?{" nil t)
            (forward-line 1))
          (hs-hide-level 1))
        (when (= (length (overlays-in (point-min) (point-max))) starting-ov-count)
          (hs-show-all)
          (recenter)))
    (hs-toggle-all)))

(defun my-hs-toggle-hiding ()
  (interactive)
  (hs-minor-mode 1)
  (hs-toggle-hiding))

(defun my-hide-all ()
  (interactive)
  (hs-minor-mode 1)
  (hs-hide-all))

;; (add-hook 'prog-mode-hook 'my-hide-all)


(provide 'my-hideshow)
