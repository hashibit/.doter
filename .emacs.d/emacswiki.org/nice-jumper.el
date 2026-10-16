;;; nice-jumper.el --- Jump like vimmers do! -*- lexical-binding: t -*-

;; Copyright (C) 2016 adapted by Martin Albrecht
;; Copyright (C) 2014-2016 by Bailey Ling
;; Author: Bailey Ling
;; URL: https://github.com/bling/nice-jumper
;; Filename: nice-jumper.el
;; Description: Jump like vimmers do! (for older versions of evil-mode)
;; Created: 2014-07-01
;; Version: 0.3.1
;; Keywords: evil vim jumplist jump list
;; Package-Requires: ((cl-lib "0.5"))
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Commentary:
;;
;; nice-jumper is an add-on for older versions of evil-mode (prior
;; to Feb 2016) which replaces the implementation the jump list such
;; that it mimics more closely with Vim's behavior.  Specifically, it
;; will jump across buffer boundaries and revive dead buffers if
;; necessary.  The jump list can also be persisted to history file
;; using `savehist' and restored
;; between sessions.
;;
;; Install:
;;
;; (require 'nice-jumper)
;;
;; Usage:
;;
;; (nice-jumper-mode t)

;;; Code:

(require 'cl-lib)

(defgroup nice-jumper nil
  "nice-jumper configuration options."
  :prefix "nice-jumper")

(defcustom nice-jumper-max-length 100
  "The maximum number of jumps to keep track of."
  :type 'integer
  :group 'nice-jumper)

(defcustom nice-jumper-pre-jump-hook nil
  "Hooks to run just before jumping to a location in the jump list."
  :type 'hook
  :group 'nice-jumper)

(defcustom nice-jumper-post-jump-hook nil
  "Hooks to run just after jumping to a location in the jump list."
  :type 'hook
  :group 'nice-jumper)

(defcustom nice-jumper-ignored-file-patterns '("COMMIT_EDITMSG$" "TAGS$")
  "A list of pattern regexps to match on the file path to exclude from being included in the jump list."
  :type '(repeat string)
  :group 'nice-jumper)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar nice-jumper--jumping nil)
(defvar nice-jumper--debug nil)
(defvar nice-jumper--wired nil)

(defvar nice-jumper--buffer-targets "\\*\\(new\\|scratch\\)\\*"
  "Regexp to match against `buffer-name' to determine whether it's a valid jump target.")

(defvar nice-jumper--window-jumps (make-hash-table)
  "Hashtable which stores all jumps on a per window basis.")

(defvar nice-jumper--jump-list nil
  "Printable version of `nice-jumper--window-jumps'.")

(cl-defstruct nice-jumper-struct
  jumps
  (idx -1))

(defun nice-jumper--message (format &rest args)
  (when nice-jumper--debug
    (setq format (concat "nice-jumper: " format))
    (apply 'message format args)))

(defun nice-jumper--get-current (&optional window)
  (unless window
    (setq window (frame-selected-window)))
  (let* ((jump-struct (gethash window nice-jumper--window-jumps)))
    (unless jump-struct
      (setq jump-struct (make-nice-jumper-struct))
      (puthash window jump-struct nice-jumper--window-jumps))
    jump-struct))

(defun nice-jumper--get-window-jump-list ()
  (let ((struct (nice-jumper--get-current)))
    (nice-jumper-struct-jumps struct)))

(defun nice-jumper--set-window-jump-list (list)
  (let ((struct (nice-jumper--get-current)))
    (setf (nice-jumper-struct-jumps struct) list)))

(defun nice-jumper--savehist-sync ()
  "Updates the printable value of window jumps for `savehist'."
  (setq nice-jumper--jump-list
        (cl-remove-if-not #'identity
                          (mapcar #'(lambda (jump)
                                      (let* ((mark (car jump))
                                             (pos (if (markerp mark)
                                                      (marker-position mark)
                                                    mark))
                                             (file-name (cadr jump)))
                                        (if (and (not (file-remote-p file-name))
                                                 (file-exists-p file-name)
                                                 pos)
                                            (list pos file-name)
                                          nil)))
                                  (nice-jumper--get-window-jump-list)))))

(defun nice-jumper--jump-to-index (idx)
  (let ((target-list (nice-jumper--get-window-jump-list)))
    (when (and (< idx (length target-list))
               (>= idx 0))
      (run-hooks 'nice-jumper-pre-jump-hook)
      (setf (nice-jumper-struct-idx (nice-jumper--get-current)) idx)
      (let* ((place (nth idx target-list))
             (pos (car place))
             (file-name (cadr place)))
        (setq nice-jumper--jumping t)
        (if (string-match-p nice-jumper--buffer-targets file-name)
            (switch-to-buffer file-name)
          (find-file file-name))
        (setq nice-jumper--jumping nil)
        (goto-char pos)
        (run-hooks 'nice-jumper-post-jump-hook)))))

(defun nice-jumper--push ()
  "Pushes the current cursor/file position to the jump list."
  (let ((target-list (nice-jumper--get-window-jump-list)))
    (while (> (length target-list) nice-jumper-max-length)
      (nbutlast target-list 1))
    (let ((file-name (buffer-file-name))
          (buffer-name (buffer-name))
          (current-pos (point-marker))
          (first-pos nil)
          (first-file-name nil)
          (excluded nil))
      (when (and (not file-name)
                 (string-match-p nice-jumper--buffer-targets buffer-name))
        (setq file-name buffer-name))
      (when file-name
        (dolist (pattern nice-jumper-ignored-file-patterns)
          (when (string-match-p pattern file-name)
            (setq excluded t)))
        (unless excluded
          (when target-list
            (setq first-pos (caar target-list))
            (setq first-file-name (car (cdar target-list))))
          (unless (and (equal first-pos current-pos)
                       (equal first-file-name file-name))
            (push `(,current-pos ,file-name) target-list)))))
    (nice-jumper--message "%s %s" (selected-window) (car target-list))
    (nice-jumper--set-window-jump-list target-list)))

(defun nice-jumper--set-jump ()
  (unless nice-jumper--jumping
    ;; clear out intermediary jumps when a new one is set
    (let* ((struct (nice-jumper--get-current))
           (target-list (nice-jumper-struct-jumps struct))
           (idx (nice-jumper-struct-idx struct)))
      (nbutlast target-list idx)
      (setf (nice-jumper-struct-jumps struct) target-list)
      (setf (nice-jumper-struct-idx struct) -1))
    (nice-jumper--push)))

(defun nice-jumper/backward ()
  (interactive)
  (let* ((struct (nice-jumper--get-current))
         (idx (nice-jumper-struct-idx struct)))
    (when (= idx -1)
      (setq idx (+ idx 1))
      (setf (nice-jumper-struct-idx struct) idx)
      (nice-jumper--push))
    (nice-jumper--jump-to-index (+ idx 1))))

(defun nice-jumper/forward ()
  (interactive)
  (let* ((struct (nice-jumper--get-current))
         (idx (nice-jumper-struct-idx struct)))
    (nice-jumper--jump-to-index (- idx 1))))

(defun nice-jumper--window-configuration-hook (&rest args)
  (let* ((window-list (window-list-1 nil nil t))
         (existing-window (selected-window))
         (new-window (previous-window)))
    (when (and (not (eq existing-window new-window))
               (> (length window-list) 1))
      (let* ((target-jump-struct (nice-jumper--get-current new-window))
             (target-jump-count (length (nice-jumper-struct-jumps target-jump-struct))))
        (if (nice-jumper-struct-jumps target-jump-struct)
            (nice-jumper--message "target window %s already has %s jumps" new-window target-jump-count)
          (nice-jumper--message "new target window detected; copying %s to %s" existing-window new-window)
          (let* ((source-jump-struct (nice-jumper--get-current existing-window))
                 (source-list (nice-jumper-struct-jumps source-jump-struct)))
            (when (= (length (nice-jumper-struct-jumps target-jump-struct)) 0)
              (setf (nice-jumper-struct-idx target-jump-struct) (nice-jumper-struct-idx source-jump-struct))
              (setf (nice-jumper-struct-jumps target-jump-struct) (copy-sequence source-list)))))))
    ;; delete obsolete windows
    (maphash (lambda (key val)
               (unless (member key window-list)
                 (nice-jumper--message "removing %s" key)
                 (remhash key nice-jumper--window-jumps)))
             nice-jumper--window-jumps)))

(defun nice-jumper--savehist-init ()
  (unless nice-jumper--wired
    (nice-jumper--set-window-jump-list nice-jumper--jump-list)
    (eval-after-load 'savehist
      '(progn
         (push 'nice-jumper--jump-list savehist-additional-variables)
         (add-hook 'savehist-save-hook #'nice-jumper--savehist-sync)))
    (setq nice-jumper--wired t)))

;;;###autoload
(define-minor-mode nice-jumper-mode
  "Global minor mode for vim jumplist emulation."
  :global t
  (if nice-jumper-mode
      (progn
        (nice-jumper--savehist-init)
        (add-hook 'next-error-hook #'nice-jumper--set-jump)
        (add-hook 'window-configuration-change-hook #'nice-jumper--window-configuration-hook)
        ;; (defadvice recenter (before nice-jumper activate)
        ;;   (nice-jumper--set-jump))
        (defadvice deadgrep (before nice-jumper activate)
          (nice-jumper--set-jump))
        (defadvice beginning-of-buffer (before nice-jumper activate)
          (nice-jumper--set-jump))
        (defadvice end-of-buffer (before nice-jumper activate)
          (nice-jumper--set-jump))
        (defadvice isearch-exit (before nice-jumper activate)
          (nice-jumper--set-jump))
        (defadvice find-file (before nice-jumper activate)
          (nice-jumper--set-jump))
        (defadvice switch-to-buffer (before nice-jumper activate)
          (nice-jumper--set-jump))
        (defadvice split-window-internal (before nice-jumper activate)
          (nice-jumper--set-jump))
        (defadvice find-tag-noselect (before nice-jumper activate)
          (nice-jumper--set-jump)))
    (when nice-jumper--wired
      (remove-hook 'next-error-hook #'nice-jumper--set-jump)
      (remove-hook 'window-configuration-change-hook #'nice-jumper--window-configuration-hook)
      ;; (ad-remove-advice 'recenter 'before 'nice-jumper)
      (ad-remove-advice 'deadgrep 'before 'nice-jumper)
      (ad-remove-advice 'beginning-of-buffer 'before 'nice-jumper)
      (ad-remove-advice 'end-of-buffer 'before 'nice-jumper)
      (ad-remove-advice 'isearch-exit 'before 'nice-jumper)
      (ad-remove-advice 'find-file 'before 'nice-jumper)
      (ad-remove-advice 'switch-to-buffer 'before 'nice-jumper)
      (ad-remove-advice 'split-window-internal 'before 'nice-jumper)
      (ad-remove-advice 'find-tag-noselect 'before 'nice-jumper))))

;;;###autoload
(defun turn-on-nice-jumper-mode ()
  "Turn on vim jumplist emulation."
  (interactive)
  (nice-jumper-mode t))

;;;###autoload
(defun turn-off-nice-jumper-mode ()
  "Turn off vim jumplist emulation."
  (interactive)
  (nice-jumper-mode -1))

;;;###autoload
(defalias 'global-nice-jumper-mode 'nice-jumper-mode)

(provide 'nice-jumper)

;;; nice-jumper.el ends here
