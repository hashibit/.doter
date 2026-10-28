;; -*- lexical-binding: t -*-
;;; init-cmake-project.el --- CMake Project Configuration

;;; Commentary:
;;
;;  CMake project management and cmake-ts-mode configuration
;;

;;; Code:

(defun maybe-cmake-project-mode ()
  "Enable `cmake-project-mode' inside a directory tree with CMakeLists.txt."
  (when (locate-dominating-file default-directory "CMakeLists.txt")
    (cmake-project-mode)))

(defvar my-cmake-project-mode-map
  (let ((map (make-sparse-keymap)))
    (keymap-set map "C-c C-c" #'compile)
    (keymap-set map "s-b" #'compile)
    map)
  "my-cmake-project-mode-map keymap.")

(use-package cmake-project
  :ensure t
  :commands cmake-project-mode
  :config
  (setq cmake-project-default-build-dir-name "build/")
  ;; 作为 cmake-project-mode 的 minor mode keymap，不替换 major mode 的 local map
  (setf (alist-get 'cmake-project-mode minor-mode-map-alist) my-cmake-project-mode-map))

(defun my-cmake-ts-mode-hook ()
  (setq-local cmake-ts-indent-offset 4))

(use-package cmake-ts-mode
  :ensure nil  ; Built-in with Emacs 29+
  :hook (cmake-ts-mode . my-cmake-ts-mode-hook)
  :bind (:map cmake-ts-mode-map
              ("C-c C-b" . compile)
              ("s-b" . compile)))

(provide 'init-cmake-project)

;;; init-cmake-project.el ends here
