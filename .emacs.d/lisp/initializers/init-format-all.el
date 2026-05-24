(use-package format-all
  :commands format-all-mode
  :hook
  (prog-mode . format-all-mode)
  (prog-mode . format-all-ensure-formatter)
  :init
  (setq-default format-all-formatters
      '(("Rust" (rustfmt "--edition" "2021" "--config" "max_width=120"))
        ("Clojure" cljfmt)
        ("HTML" prettier)))
  ;;   :config
  ;;   (setq-default format-all-formatters
  ;;                 '(("C"     (astyle "--mode=c"))
  ;;                   ("Shell" (shfmt "-i" "4" "-ci"))))
  )



(provide 'init-format-all)
