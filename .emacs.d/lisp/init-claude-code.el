;; -*- lexical-binding: t -*-
;;; init-claude-code.el

;;; Code:

(use-package claude-code
  :ensure t
  :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
  :bind-keymap
  ("C-c c" . claude-code-command-map) ;; or your preferred key
  :bind
  (("s-\"" . claude-code-toggle)
    ("s-S-<return>" . claude-code-send-return)
    ("s-S-<backspace>" . claude-code-send-escape)
    ("s-Y" . claude-code-send-region)
    ("s-y" . my-send-command-with-buffer-or-region-context)
    ("s-:" . claude-code-send-command))
  :hook
  (prog-mode . claude-code-mode)
  :config
  (add-to-list 'display-buffer-alist
    '("^\\*claude"
       (display-buffer-in-side-window)
       (side . right)
       (window-width . 90)
       (window-parameters . ((no-other-window . nil)))))
  (setq claude-code-terminal-backend 'vterm)
  (setq claude-code-vterm-buffer-multiline-output nil)
  (setq claude-code-sandbox-program "claude")

  (defun my-send-command-with-buffer-or-region-context (cmd &optional arg)
    "Send CMD to Claude with context:
- If region is active: include file + selected line range.
- Otherwise: include the whole file (no line numbers).
With prefix ARG, switch to Claude buffer after sending."
    (interactive "sClaude command: \nP")
    (let* ((file (claude-code--get-buffer-file-name)))
      (unless file
        (error "Current buffer is not associated with a file"))
      (let* ((context (if (use-region-p)
                        (claude-code--format-file-reference
                          file
                          (line-number-at-pos (region-beginning))
                          (line-number-at-pos (region-end)))
                        (format "@%s" file))) ; ← 整个文件，无行号
              (cmd-with-context (format "%s\n%s" cmd context))
              (claude-buffer (claude-code--do-send-command cmd-with-context)))
        (unless (get-buffer-window claude-buffer) (claude-code-toggle)))))

  (defun my-select-claude-window ()
    "Select the claude-code window if visible."
    (let ((claude-window (seq-find (lambda (win)
                                     (string-match-p "^\\*claude:" (buffer-name (window-buffer win))))
                           (window-list))))
      (when claude-window (select-window claude-window))))

  (advice-add 'claude-code-send-region :after #'(lambda(&arg) (deactivate-mark)(beginning-of-line)))
  (advice-add 'claude-code-toggle :after #'my-select-claude-window)
  )


(setq my-glm-api-key nil)
(defun claude-code-glm (&optional api-key)
  (interactive)
  (when (called-interactively-p 'interactive)
    (setq api-key (read-string "API Key: ")))
  (when (and api-key (not (string-empty-p api-key)))
    (setq my-glm-api-key api-key))
  (if my-glm-api-key
    (progn
      (setenv "ANTHROPIC_BASE_URL" "https://open.bigmodel.cn/api/anthropic")
      (setenv "ANTHROPIC_AUTH_TOKEN" my-glm-api-key)
      (setenv "http_proxy" nil)
      (setenv "https_proxy" nil)
      (setenv "HTTP_PROXY" nil)
      (setenv "HTTPS_PROXY" nil)
      (claude-code)
      )
    (message "should set api-key")))


;; (use-package claudemacs
;;   :vc (:fetcher github :repo "cpoile/claudemacs"))


(provide 'init-claude-code)

;;; init-ansible.el ends here
