;; -*- lexical-binding: t -*-
;;; init-claude-code.el

;;; Code:


;; install required inheritenv dependency:
(use-package inheritenv
  :vc (:url "https://github.com/purcell/inheritenv" :rev :newest))

(use-package claude-code
  :ensure t
  :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
  :bind-keymap
  ("C-c c" . claude-code-command-map) ;; or your preferred key
  :bind
  (("s-\"" . claude-code-toggle)
    ("s-S-<return>" . claude-code-send-return)
    ("s-S-<backspace>" . claude-code-send-escape)
    ("s-:" . claude-code-send-command))
  :hook
  (prog-mode . claude-code-mode)
  :config
  (add-to-list 'display-buffer-alist
    '("^\\*claude"
       (display-buffer-in-side-window)
       (side . right)
       (window-width . 120)
       (window-parameters . ((no-other-window . nil)))))
  (set-face-attribute 'claude-code-repl-face nil
    :background "#1e1e1e"
    :foreground "#d4d4d4")
  (setq claude-code-terminal-backend 'eat)
  (setq claude-code-sandbox-program "claude")
  (setq claude-code-newline-keybinding-style 'newline-on-alt-return)

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
                        (format "@%s\n" file)))
              (cmd-with-context (format "%s\n%s" cmd context))
              (claude-buffer (claude-code--do-send-command cmd-with-context)))
        (unless (get-buffer-window claude-buffer) (claude-code-toggle)))))

  ;; (defun my-select-claude-window ()
  ;;   "Select the claude-code window if visible."
  ;;   (let ((claude-window (seq-find (lambda (win)
  ;;                                    (string-match-p "^\\*claude:" (buffer-name (window-buffer win))))
  ;;                          (window-list))))
  ;;     (when claude-window
  ;;       (select-window claude-window)
  ;;       (when (eq claude-code-terminal-backend 'eat)
  ;;         (goto-char (point-max))))))

  (defun my-claude-code-deactivate-after-send (&rest _)
    (deactivate-mark)
    (beginning-of-line))
  (advice-add 'claude-code-send-region :after #'my-claude-code-deactivate-after-send)
  (advice-add 'my-send-command-with-buffer-or-region-context :after #'my-claude-code-deactivate-after-send)

  (setq claude-code-toggle-auto-select t)
  ;; (advice-add 'claude-code-toggle :after #'my-select-claude-window)
  )


(defvar my-bailian-api-key nil
  "Aliyun Bailian API key, entered at runtime (never stored in this file).")
(defun claude-code-bailian (&optional api-key)
  (interactive)
  (when (called-interactively-p 'interactive)
    (setq api-key (read-string "API Key: ")))
  (when (and api-key (not (string-empty-p api-key)))
    (setq my-bailian-api-key api-key))
  (if my-bailian-api-key
    (progn
      (setenv "ANTHROPIC_BASE_URL" "https://coding.dashscope.aliyuncs.com/apps/anthropic")
      (setenv "ANTHROPIC_MODEL" "glm-5")
      (setenv "ANTHROPIC_AUTH_TOKEN" my-bailian-api-key)
      ;; (setenv "http_proxy" nil)
      ;; (setenv "https_proxy" nil)
      ;; (setenv "HTTP_PROXY" nil)
      ;; (setenv "HTTPS_PROXY" nil)
      (claude-code)
      )
    (message "should set aliyun bailian api-key")))

(defvar my-ds-api-key nil
  "DeepSeek API key, entered at runtime (never stored in this file).")
(defun claude-code-ds (&optional api-key)
  (interactive)
  (when (called-interactively-p 'interactive)
    (setq api-key (read-string "DeepSeek API Key: ")))
  (when (and api-key (not (string-empty-p api-key)))
    (setq my-ds-api-key api-key))
  (if my-ds-api-key
    (progn
      (setenv "ANTHROPIC_BASE_URL" "https://api.deepseek.com/anthropic")
      (setenv "ANTHROPIC_AUTH_TOKEN" my-ds-api-key)
      ;; (setenv "ANTHROPIC_MODEL" "deepseek-v4-pro[1m]")
      ;; (setenv "ANTHROPIC_DEFAULT_OPUS_MODEL" "deepseek-v4-pro[1m]")
      ;; (setenv "ANTHROPIC_DEFAULT_SONNET_MODEL" "deepseek-v4-pro[1m]")
      (setenv "ANTHROPIC_MODEL" "deepseek-v4-flash")
      (setenv "ANTHROPIC_DEFAULT_OPUS_MODEL" "deepseek-v4-flash")
      (setenv "ANTHROPIC_DEFAULT_SONNET_MODEL" "deepseek-v4-flash")
      (setenv "ANTHROPIC_DEFAULT_HAIKU_MODEL" "deepseek-v4-flash")
      (setenv "CLAUDE_CODE_SUBAGENT_MODEL" "deepseek-v4-flash")
      (setenv "CLAUDE_CODE_EFFORT_LEVEL" "max")
      (setenv "CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN" "1")
      (claude-code)
      )
    (message "should set deepseek api-key")))


(defun reset-claude-code-env()
  (interactive)
  (setenv "ANTHROPIC_BASE_URL" nil)
  (setenv "ANTHROPIC_MODEL" nil)
  (setenv "ANTHROPIC_AUTH_TOKEN" nil))

(defun claude-code-origin()
  (interactive)
  (reset-claude-code-env)
  (claude-code))

;; (use-package claudemacs
;;   :vc (:fetcher github :repo "cpoile/claudemacs"))


(provide 'init-claude-code)

;;; init-claude-code.el ends here
