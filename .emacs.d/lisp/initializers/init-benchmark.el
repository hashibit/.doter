;; -*- lexical-binding: t -*-
;;; init-benchmark.el --- Benchmark Init Configuration

;;; Commentary:
;;
;;  Benchmark startup time
;;

;;; Code:

(use-package benchmark-init
  :ensure t
  :demand t
  :config
  ;; To disable collection of benchmark data after init is done.
  (add-hook 'after-init-hook 'benchmark-init/deactivate))

(provide 'init-benchmark)

;;; init-benchmark.el ends here