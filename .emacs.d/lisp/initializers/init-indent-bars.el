;; -*- lexical-binding: t -*-
;;; init-indent-bars.el --- Indent Bars Configuration

;;; Commentary:
;;
;;  Indentation guide bars
;;

;;; Code:

(defun my/indent-bars-enable-maybe ()
  "Enable indent-bars-mode unless the buffer uses tab indentation."
  (unless (save-excursion
            (goto-char (point-min))
            (re-search-forward "^\t" nil t))
    (indent-bars-mode 1)))

(use-package indent-bars
  :custom
  (indent-bars-no-descend-lists t) ; no extra bars in continued func arg lists
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  ;; Minimal colorpop:
  (indent-bars-color '(highlight :face-bg t :blend 0.2))
  (indent-bars-pattern ".")
  (indent-bars-width-frac 0.1)
  (indent-bars-pad-frac 0.1) ; middle of char
  (indent-bars-zigzag nil)
  (indent-bars-color-by-depth '(:regexp "outline-\\([0-9]+\\)" :blend 1) ); blend=1: blend with BG only
  (indent-bars-highlight-current-depth nil) ; pump up the BG blend on current
  (indent-bars-display-on-blank-lines nil)
  :hook
  (prog-mode . my/indent-bars-enable-maybe)
  (indent-bars-mode . indent-bars-reset))

(provide 'init-indent-bars)

;;; init-indent-bars.el ends here
