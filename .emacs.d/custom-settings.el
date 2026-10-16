;;; custom-settings.el --- Customize-managed faces and variables -*- lexical-binding: t -*-

;; This is `custom-file'; Customize writes here.  Hand-written settings
;; belong in init.el or lisp/.

;;; Custom Faces Configuration
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
  '(avy-lead-face ((t (:background "#161c23" :weight normal :foreground "deeppink"))))
  '(avy-lead-face-0 ((t (:background "#161c23" :foreground "#FFB400"))))
  '(aw-mode-line-face ((t (:inherit nil))))
  '(bold ((t (:slant normal :weight normal :height 130 :width normal :foundry "nil" :family "IBM Plex Mono"))))
  '(cfrs-border-color ((t (:background "yellow"))))
  '(company-tooltip ((t (:background "black"))))
  '(company-tooltip-annotation ((t (:foreground "#7F848E" :slant normal :weight normal))))
  '(company-tooltip-annotation-selection ((t (:foreground "#7F848E" :slant normal :weight normal))))
  '(company-tooltip-common ((t (:foreground "#61AFEF" :weight normal))))
  '(company-tooltip-common-selection ((t (:foreground "#61AFEF" :weight normal))))
  '(company-tooltip-scrollbar-thumb ((t (:background "#3E4451"))))
  '(company-tooltip-scrollbar-track ((t (:background "#2a2931"))))
  '(company-tooltip-selection ((t (:background "#3E4451" :foreground "#d4d4d6" :weight normal))))
  '(deadgrep-match-face ((t (:inherit lazy-highlight))))
  '(eat-term-bold ((t (:inherit nil))))
  '(eat-term-color-0 ((t (:foreground "black"))))
  '(eat-term-color-1 ((t (:foreground "tomato"))))
  '(eat-term-color-10 ((t (:foreground "PaleGreen2"))))
  '(eat-term-color-11 ((t (:foreground "gold1"))))
  '(eat-term-color-12 ((t (:foreground "DeepSkyBlue1"))))
  '(eat-term-color-13 ((t (:foreground "MediumOrchid1"))))
  '(eat-term-color-14 ((t (:foreground "cyan"))))
  '(eat-term-color-15 ((t (:foreground "white"))))
  '(eat-term-color-2 ((t (:foreground "PaleGreen2"))))
  '(eat-term-color-3 ((t (:foreground "gold1"))))
  '(eat-term-color-4 ((t (:foreground "DeepSkyBlue1"))))
  '(eat-term-color-5 ((t (:foreground "MediumOrchid1"))))
  '(eat-term-color-6 ((t (:foreground "cyan"))))
  '(eat-term-color-7 ((t (:foreground "white"))))
  '(eat-term-color-8 ((t (:foreground "gray50"))))
  '(eat-term-color-9 ((t (:foreground "tomato"))))
  '(eat-term-faint ((t (:inherit font-lock-comment-face :weight light))))
  '(eglot-diagnostic-tag-deprecated-face ((t (:underline nil :strike-through nil :foreground "yellow"))))
  '(eglot-diagnostic-tag-unnecessary-face ((t (:foreground "gray" :underline nil))))
  '(eglot-mode-line ((t (:inherit nil :weight bold))))
  '(eldoc-box-border ((t (:background "#569CD6"))))
  '(flymake-error ((t (:foreground unspecified :background "#3c2020" :underline nil :weight normal))))
  '(flymake-note ((t (:underline nil))))
  '(flymake-warning ((t (:underline nil))))
  '(font-lock-doc-face ((t (:inherit font-lock-comment-face :foreground "#6A9955"))))
  '(font-lock-keyword-face ((t (:foreground "orchid" :weight normal))))
  '(font-lock-preprocessor-face ((t (:weight normal))))
  '(fringe ((t (:foreground unspecified :background unspecified :inherit default))))
  '(highlight-indent-guides-character-face ((t (:inherit font-lock-doc-markup-face))))
  '(iedit-occurrence ((t (:foreground "black" :background "yellow"))))
  '(isearch ((t (:foreground "white" :background "deeppink" :weight normal))))
  '(ivy-minibuffer-match-face-1 ((t (:weight regular))))
  '(ivy-minibuffer-match-face-2 ((t (:weight regular))))
  '(ivy-minibuffer-match-face-3 ((t (:weight regular))))
  '(ivy-minibuffer-match-face-4 ((t (:weight regular))))
  '(lazy-highlight ((t (:background "#7FDC59" :foreground "#161c23" :weight normal))))
  '(line-number ((t (:inherit default :foreground "gray33" :slant normal :weight normal))))
  '(line-number-current-line ((t (:background "#1b2129" :foreground "white" :slant normal :weight normal))))
  '(markdown-bold-face ((t (:inherit nil))))
  '(markdown-code-face ((t (:background unspecified))))
  '(markdown-header-face ((t (:foreground "#49bdb0" :weight regular))))
  '(mode-line ((t (:background "#415367" :foreground "#e5ded6" :underline (:color foreground-color :style line :position t)))))
  '(mode-line-active ((t (:background "#1a202c" :foreground "green" :box nil :underline nil))))
  '(mode-line-highlight ((t (:box nil :foreground "green"))))
  '(mode-line-inactive ((t (:background "#1a202c" :foreground "#a0aec0" :box nil :underline nil))))
  '(region ((t (:background "#1a3a5c"))))
  '(rg-context-face ((t (:inherit nil :foreground "#C6B8AD"))))
  '(rg-match-face ((t (:inherit lazy-highlight))))
  '(ripgrep-match-face ((t (:inherit my-highlight-font-words-face))))
  '(shadow ((t (:foreground "#569CD6"))))
  '(show-paren-match ((t (:foreground "green" :background "#11501B" :weight normal :underline (:position t)))))
  '(sideline-flymake-error ((t (:inherit nil :background "red" :foreground "white"))))
  '(sideline-flymake-note ((t (:inherit nil :background "lightblue" :foreground "black"))))
  '(sideline-flymake-warning ((t (:inherit nil :background "lightyellow" :foreground "black"))))
  '(success ((t (:foreground "Green1" :weight regular))))
  '(symbol-overlay-default-face ((t (:inherit my-highlight-font-words-face))))
  '(tab-bar ((t (:background "#1e1e1e"))))
  '(tab-bar-tab ((t (:background "#199DFF" :distant-foreground "black" :foreground "#199DFF" :box (:line-width (2 . 2) :color "#199DFF" :style flat-button) :height 1.0))))
  '(tooltip ((t (:font "IBM Plex Mono-14.0" :box nil))))
  '(treemacs-directory-collapsed-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#57D8D4"))))
  '(treemacs-directory-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#57D8D4"))))
  '(treemacs-file-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-added-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-conflict-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-ignored-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-modified-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#D0BF68"))))
  '(treemacs-git-renamed-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-unmodified-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-git-untracked-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(treemacs-root-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#57D8D4"))))
  '(treemacs-tags-face ((t (:family "IBM Plex Mono" :weight normal :underline nil :inherit unspecified :foreground "#C6B8AD"))))
  '(vertical-border ((t (:inherit shadow :foreground "#2d3748"))))
  '(whitespace-tab ((t (:foreground unspecified :background unspecified :inherit shadow))))
  '(whitespace-trailing ((t (:foreground unspecified :background unspecified :inherit shadow))))
  '(widget-field ((t (:background "#C6B8AD" :foreground "black"))))
  '(window-divider ((t (:foreground "#2d3748" :inherit shadow))))
  '(window-divider-first-pixel ((t (:inherit shadow))))
  '(window-divider-last-pixel ((t (:inherit shadow))))
  '(yas-field-highlight-face ((t (:inherit my-highlight-font-words-face)))))

;;; Custom Variables
(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
  '(helm-minibuffer-history-key "M-p")
  '(leetcode-prefer-language "cpp")
  '(leetcode-save-solutions t)
  '(package-selected-packages
     '(jtsx sideline-eglot sideline-flymake sideline
        highlight-indent-guides treemacs-nerd-icons treemacs python-ts
        poetry dockerfile-mode popper spacious-padding afternoon-theme
        ansible apheleia atom-one-dark-theme auto-dim-other-buffers
        bazel beacon benchmark-init blamer centaur-tabs
        challenger-deep-theme color-theme-sanityinc-tomorrow
        company-posframe company-prescient company-qml corfu-terminal
        counsel csv-mode cyberpunk-theme dashboard dashboard-hackernews
        diminish disable-mouse easy-kill eglot elisp-autofmt elisp-def
        elisp-refs elisp-slime-nav eterm-256color format-all general
        google-c-style helm-rg highlight-numbers highlight-parentheses
        imenu-list impatient-mode inkpot-theme ivy ivy-posframe
        ivy-xref jdecomp jsonrpc key-chord known leetcode lispy
        lsp-python-ms markdown-mode markdown-toc markdownfmt
        modus-themes moe-theme mwim nano-theme neotree nimbus-theme
        package-lint paredit phi-search popon popup-switcher popwin
        prescient project projectsile-mode protobuf-mode py-autopep8
        qml-mode rainbow-delimiters reformatter ripgrep rjsx-mode
        selected slime slime-company smart-jump smart-mode-line
        smooth-scrolling solaire-mode srcery-theme srefactor swift-mode
        switch-buffer-functions symbol-overlay treemacs-all-the-icons
        treesit-auto typescript-mode undo-tree valign vs-dark-theme
        vscode-dark-plus-theme vterm vue-mode with-proxy
        with-simulated-input xclip yasnippet))
  '(package-vc-selected-packages
     '((claude-code :url "https://github.com/stevemolitor/claude-code.el")))
  '(pos-tip-background-color "#1d1d2b")
  '(pos-tip-foreground-color "#d4d4d6")
  '(safe-local-variable-values
     '((eval setq-local cider-preferred-build-tool 'clojure-cli
         cider-default-cljs-repl 'shadow)
        (projectile-project-root
          . "/Users/jiechen/work/code/clj/ringbell")
        (python-shell-interpreter-args . "run python")
        (projectile-project-root . ".")
        (python-shell-interpreter-args . "python -i")
        (python-shell-interpreter . "uv")
        (eglot-server-programs
          (python-mode "basedpyright-langserver" "--stdio"))))
  '(typescript-ts-indent-offset 2 nil nil "Customized with use-package jtsx")
  '(warning-suppress-log-types '((emacs) (use-package) (lsp-mode)))
  '(warning-suppress-types '((use-package) (lsp-mode))))

;;; custom-settings.el ends here
