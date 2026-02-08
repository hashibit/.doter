;;; emacs-translate.el --- Translate buffer to target language via LLM  -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: Seki Rocc
;; Version: 0.2.0
;; Package-Requires: ((emacs "27.1") (gptel "0.9.0"))
;; Keywords: translate, llm, tools
;; URL: https://github.com/sekirocc/emacs-translate

;;; Commentary:

;; Translate the current buffer via LLM to a target language; show the result
;; in a new buffer.  Uses gptel for LLM interaction (configure gptel-backend,
;; gptel-model, etc.).  M-x emacs-translate-buffer, or bind a key to it.
;;
;; The translation is shown in a buffer named "*Translation-<current buffer name>*".

;;; Code:

(require 'gptel)

(defgroup emacs-translate nil
  "Translate buffer content via LLM (using gptel)."
  :group 'tools
  :prefix "emacs-translate-")

(defcustom emacs-translate-language-alist
  '(("English" . "English")
    ("Simplified Chinese" . "Simplified Chinese")
    ("Traditional Chinese" . "Traditional Chinese")
    ("Japanese" . "Japanese")
    ("Korean" . "Korean")
    ("French" . "French")
    ("German" . "German")
    ("Spanish" . "Spanish")
    ("Russian" . "Russian")
    ("Arabic" . "Arabic")
    ("Portuguese" . "Portuguese")
    ("Italian" . "Italian"))
  "Target languages: (display name . name for prompt).  First is default."
  :type '(repeat (cons (string :tag "Display name") (string :tag "Prompt name")))
  :group 'emacs-translate)

(defun emacs-translate--buffer-name ()
  "Return the translation buffer name for the current buffer."
  (format "*Translation-%s*" (buffer-name)))

(defun emacs-translate--read-language ()
  "Let user choose target language; return prompt name.  Default is first (English)."
  (let* ((choices (mapcar #'car emacs-translate-language-alist))
         (default (car choices))
         (selected (completing-read
                    (format "Target language (default %s): " default)
                    choices nil t nil nil default)))
    (alist-get selected emacs-translate-language-alist nil nil #'string=)))

(defun emacs-translate--build-prompt (text target-lang)
  "Build translation prompt for TEXT and TARGET-LANG."
  (format "Translate the following into %s.  Output only the translated text, no explanation, title, or quotes.  Preserve paragraphs and line breaks.\n\n%s"
          target-lang text))

;;;###autoload
(defun emacs-translate-buffer (&optional target-lang)
  "Translate current buffer to TARGET-LANG; show result in *Translation-<buffer name>*.
If TARGET-LANG is nil, prompt for target language (default: English).
Uses gptel for the LLM request (see gptel-backend, gptel-model)."
  (interactive)
  (unless target-lang
    (setq target-lang (emacs-translate--read-language)))
  (let ((text (buffer-substring-no-properties (point-min) (point-max))))
    (if (string-blank-p (string-trim text))
        (user-error "Current buffer is empty")
      (let ((result-buf-name (emacs-translate--buffer-name))
            (source-mode major-mode))
        (message "Translating to %s ..." target-lang)
        (gptel-request (emacs-translate--build-prompt text target-lang)
          :callback (lambda (response _info)
                      (if (not response)
                          (message "Translation request failed")
                        (let ((buf (get-buffer-create result-buf-name)))
                          (with-current-buffer buf
                            (funcall source-mode)
                            (erase-buffer)
                            (insert (string-trim response))
                            (goto-char (point-min))
                            (set-buffer-file-coding-system 'utf-8)
                            (view-mode 1))
                          (display-buffer buf)
                          (message "Translation done -> %s" target-lang)))))))))

(provide 'emacs-translate)
;;; emacs-translate.el ends here
