;; -*- lexical-binding: t -*-
;;; my-hyperspec.el --- Plain English mirror of the local HyperSpec

;;; Commentary:

;; The mirror is a copy of the HyperSpec dictionary pages with simpler text.
;; It lives in `my-hyperspec-cache-dir'.  It has the same file names:
;; Body/f_format.htm in the HyperSpec becomes Body/f_format.htm in the mirror.
;; Links between pages are normal relative links.  eww shows the mirror.
;;
;; `my-hyperspec-rewrite-all' makes the mirror:
;;   1. It renders each page to text, like eww does.  Links stay as [label](target).
;;   2. It sends the text to the claude CLI.  The CLI writes a small HTML subset.
;;   3. It checks the HTML, adds the Previous, Up and Next links, and saves the page.
;;   It skips pages that are already in the mirror.
;;   `my-hyperspec-rewrite-cancel' stops the batch.
;;
;; `my-hyperspec-download' gets the mirror from `my-hyperspec-repo'.
;;   Use it instead of `my-hyperspec-rewrite-all' on a new machine.
;;   `my-hyperspec-cache-dir' sets where the mirror lives.
;;
;; `my-hyperspec-eww-advice' is advice for `eww'.
;;   A link to an original page opens the mirror page, if it exists.
;;   A link to a mirror page that does not exist opens the original page.
;; `my-hyperspec-toggle' switches between the mirror page and the original page.

;;; Code:

(require 'cl-lib)
(require 'dom)
(require 'shr)
(require 'subr-x)

(declare-function eww "eww")
(defvar eww-data)

(defgroup my-hyperspec nil
  "Plain English mirror of the local HyperSpec."
  :group 'tools)

(defun my-hyperspec--set-directory (symbol value)
  "Set SYMBOL to the full directory name of VALUE.
The name ends in a slash, because the URL code needs this."
  (set-default-toplevel-value symbol (file-name-as-directory (expand-file-name value))))

(defcustom my-hyperspec-root (expand-file-name "~/.quicklisp/HyperSpec/")
  "Directory of the local HyperSpec.
Set it with `setopt' or Customize, not with `setq'."
  :type 'directory
  :set #'my-hyperspec--set-directory)

(defcustom my-hyperspec-cache-dir (expand-file-name "~/.cache/hyperspec/")
  "Directory of the mirror.
Set it with `setopt' or Customize, not with `setq'."
  :type 'directory
  :set #'my-hyperspec--set-directory)

(defcustom my-hyperspec-repo "https://github.com/hashibit/hyperspec.git"
  "Git URL of the mirror.  `my-hyperspec-download' uses it."
  :type 'string)

(defcustom my-hyperspec-model "sonnet"
  "Model name passed to the claude CLI."
  :type 'string)

(defcustom my-hyperspec-jobs 4
  "Number of claude processes that run at the same time."
  :type 'integer)

(defcustom my-hyperspec-text-width 80
  "Line width of the text that goes to the claude CLI."
  :type 'integer)

(defconst my-hyperspec-prompt
  "You rewrite one page of the Common Lisp HyperSpec for application developers.
The input is the text of the page.  Write the same page as a practical manual.

Rules for the content:
- Use plain and simple English.  Use short sentences.  Use active voice.
- Do not use legal or standards language.  Say what the symbol does and how to use it.
- Keep this order: name and kind, call syntax, what it does, arguments, return values, examples, pitfalls, formal grammar, related symbols.
- Call syntax holds only the short form of the call.  Do not put grammar rules (lines with ::=) in it.
- Move all grammar rules to an h2 named \"Formal grammar\".  Put it before the h2 for related symbols.
- Keep the grammar rules exactly as written.
- Start that section with one sentence that says it is reference material that most readers can skip.
- Keep every code example and its output exactly as written.
- Keep all facts.  Do not add behavior that the page does not state.
- Write one clear sentence for each rule about errors and undefined behavior.
- If a page covers many symbols, give each symbol its own section.

Rules for the links:
- The page text has links in the form [label](target).
- Keep each link that fits your new text.  Write it as <a href=\"target\">label</a>.
- Do not change a target.  Do not add a link that is not in the page.
- You may change the label words and move a link to another sentence.

Rules for the format:
- Output HTML only.  Do not use markdown.  Do not wrap the output in code fences.
- Use only these tags: h1, h2, p, ul, li, pre, code, a.  Use no attribute except href on a.
- Start with one h1 that holds the page title.  Use h2 for the sections.
- Put every code example, call syntax and grammar in pre.
- Write < > and & as &lt; &gt; and &amp; in the text and in pre.
- Output only the page.  Do not add comments about the task."
  "System prompt for the rewrite.")

(defvar my-hyperspec--queue nil
  "Page names that wait for a rewrite.")

(defvar my-hyperspec--running nil
  "Alist of (NAME . PROCESS) for the running rewrites.")

(defvar my-hyperspec--done 0
  "Number of finished rewrites in the current batch.")

(defvar my-hyperspec--total 0
  "Number of pages in the current batch.")

(defvar my-hyperspec--original nil
  "Non-nil while eww must open an original page without a redirect.")

;;; Files and URLs

(defun my-hyperspec--html-file (name)
  "Return the original HTML file of page NAME."
  (expand-file-name (concat "Body/" name ".htm") my-hyperspec-root))

(defun my-hyperspec--mirror-file (name)
  "Return the mirror file of page NAME."
  (expand-file-name (concat "Body/" name ".htm") my-hyperspec-cache-dir))

(defun my-hyperspec--dictionary-pages ()
  "Return the names of all dictionary pages, from Map_Sym.txt."
  (let (names)
    (with-temp-buffer
      (insert-file-contents (expand-file-name "Data/Map_Sym.txt" my-hyperspec-root))
      (while (re-search-forward "^\\.\\./Body/\\(.+\\)\\.htm$" nil t)
        (push (match-string 1) names)))
    (delete-dups (nreverse names))))

(defun my-hyperspec--split-url (url)
  "Split URL into (KIND NAME FRAGMENT), or return nil.
KIND is `original' or `mirror'.  FRAGMENT is nil or a string like \"#car\"."
  (cl-loop for (kind . root) in `((original . ,my-hyperspec-root)
                                  (mirror . ,my-hyperspec-cache-dir))
           for prefix = (concat "file://" root "Body/")
           for rest = (and (string-prefix-p prefix url)
                           (substring url (length prefix)))
           when (and rest (string-match "\\`\\([^/#]+\\)\\.htm\\(#.*\\)?\\'" rest))
           return (list kind (match-string 1 rest) (match-string 2 rest))))

(defun my-hyperspec--url (kind name fragment)
  "Return the URL of page NAME.  KIND is `original' or `mirror'."
  (concat "file://"
          (if (eq kind 'mirror) my-hyperspec-cache-dir my-hyperspec-root)
          "Body/" name ".htm" fragment))

(defun my-hyperspec--redirect (url)
  "Return the URL that eww must open instead of URL, or nil."
  (pcase (my-hyperspec--split-url url)
    (`(original ,name ,fragment)
     (and (file-exists-p (my-hyperspec--mirror-file name))
          (my-hyperspec--url 'mirror name fragment)))
    (`(mirror ,name ,fragment)
     (and (not (file-exists-p (my-hyperspec--mirror-file name)))
          (file-exists-p (my-hyperspec--html-file name))
          (my-hyperspec--url 'original name fragment)))))

;;;###autoload
(defun my-hyperspec-eww-advice (orig url &rest args)
  "Around advice for `eww'.  Redirect a HyperSpec URL.
The redirect goes to the mirror page or to the original page.
ORIG is `eww'.  URL and ARGS are its arguments.
`my-hyperspec-toggle' turns the redirect to the mirror off."
  (apply orig
         (or (and (not my-hyperspec--original)
                  (stringp url)
                  (my-hyperspec--redirect url))
             url)
         args))

;;;###autoload
(defun my-hyperspec-toggle ()
  "Switch between the mirror page and the original page in eww."
  (interactive)
  (unless (derived-mode-p 'eww-mode)
    (user-error "Not in an eww buffer"))
  (pcase (my-hyperspec--split-url (or (plist-get eww-data :url) ""))
    (`(mirror ,name ,fragment)
     (let ((my-hyperspec--original t))
       (eww (my-hyperspec--url 'original name fragment))))
    (`(original ,name ,fragment)
     (unless (file-exists-p (my-hyperspec--mirror-file name))
       (user-error "No mirror page for %s" name))
     (eww (my-hyperspec--url 'mirror name fragment)))
    (_ (user-error "This is not a HyperSpec page"))))

;;; HTML to text

(defun my-hyperspec--prune (dom)
  "Remove the page title and the navigation buttons from DOM."
  (dolist (tag '(head h1))
    (dolist (node (dom-by-tag dom tag))
      (dom-remove-node dom node)))
  (dolist (a (dom-by-tag dom 'a))
    (when (dom-by-tag a 'img)
      (dom-remove-node dom a)))
  dom)

(defun my-hyperspec--link-target (href)
  "Return the target of HREF as a file name in the Body directory, or nil.
Only links to HyperSpec body pages have a target."
  (let* ((body (expand-file-name "Body/" my-hyperspec-root))
         (target (file-relative-name (expand-file-name href body) body)))
    (and (string-match-p "\\`[^/#]+\\.htm\\(?:#.*\\)?\\'" target) target)))

(defun my-hyperspec--mark-links (dom)
  "Write each link in DOM as [label](target).  Return DOM."
  (dolist (a (dom-by-tag dom 'a))
    (when-let* ((href (dom-attr a 'href))
                (target (my-hyperspec--link-target href)))
      (setf (cddr a) (append (list "[") (cddr a) (list (format "](%s)" target))))))
  dom)

(defun my-hyperspec-html-to-text (file)
  "Return the text of HTML FILE, as eww shows it.
Links to other HyperSpec pages are written as [label](target)."
  (let ((dom (with-temp-buffer
               (insert-file-contents file)
               (libxml-parse-html-region (point-min) (point-max))))
        (shr-use-fonts nil)
        (shr-inhibit-images t)
        (shr-width my-hyperspec-text-width))
    (with-temp-buffer
      (shr-insert-document (my-hyperspec--mark-links (my-hyperspec--prune dom)))
      (string-trim (buffer-substring-no-properties (point-min) (point-max))))))

;;; Rewrite with the claude CLI

(defun my-hyperspec--nav (name)
  "Return an HTML line with the Previous, Up and Next links of page NAME.
The links come from the head of the original page."
  (let ((dom (with-temp-buffer
               (insert-file-contents (my-hyperspec--html-file name))
               (libxml-parse-html-region (point-min) (point-max))))
        links)
    (dolist (rel '(("prev" . "Previous") ("up" . "Up") ("next" . "Next")))
      (when-let* ((node (seq-find (lambda (link)
                                    (equal (downcase (or (dom-attr link 'rel) "")) (car rel)))
                                  (dom-by-tag dom 'link)))
                  (href (dom-attr node 'href))
                  (target (my-hyperspec--link-target href)))
        (push (format "<a href=\"%s\">%s</a>" target (cdr rel)) links)))
    (and links (format "<p>%s</p>" (string-join (nreverse links) " | ")))))

(defun my-hyperspec--make-page (output name)
  "Check the HTML in OUTPUT.  Return it as a complete page for page NAME.
Signal an error if the HTML is bad."
  (let* ((body (string-trim
                (replace-regexp-in-string "\\`[ \t\n]*```[a-z]*\n\\|\n```[ \t\n]*\\'" "" output)))
         (dom (with-temp-buffer
                (insert body)
                (libxml-parse-html-region (point-min) (point-max))))
         (h1 (car (dom-by-tag dom 'h1))))
    (unless h1
      (error "No h1 in the output"))
    (when (dom-by-tag dom 'script)
      (error "Script tag in the output"))
    (let ((nav (or (my-hyperspec--nav name) "")))
      (format "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<title>%s</title>\n</head>\n<body>\n%s\n<hr>\n%s\n<hr>\n%s\n</body>\n</html>\n"
              (xml-escape-string (string-trim (dom-inner-text h1)))
              nav body nav))))

(defun my-hyperspec--rewrite-done (name process)
  "Save the output of PROCESS as the mirror page NAME.  Then start the next page."
  (setq my-hyperspec--running (assq-delete-all name my-hyperspec--running))
  (let ((output (with-current-buffer (process-buffer process)
                  (string-trim (buffer-string)))))
    (condition-case err
        (progn
          (unless (and (zerop (process-exit-status process)) (not (string-empty-p output)))
            (error "claude failed: %s" output))
          (let ((file (my-hyperspec--mirror-file name))
                (coding-system-for-write 'utf-8))
            (make-directory (file-name-directory file) t)
            (write-region (my-hyperspec--make-page output name) nil file nil 'silent)))
      (error (message "my-hyperspec: rewrite of %s failed: %s" name (error-message-string err)))))
  (kill-buffer (process-buffer process))
  (cl-incf my-hyperspec--done)
  (message "my-hyperspec: %d/%d pages rewritten" my-hyperspec--done my-hyperspec--total)
  (my-hyperspec--rewrite-next))

(defun my-hyperspec--rewrite-start (name)
  "Start the rewrite of page NAME."
  (let* ((default-directory my-hyperspec-cache-dir)
         (process (make-process
                   :name (concat "hyperspec-" name)
                   :buffer (generate-new-buffer (format " *hyperspec-%s*" name))
                   :command (list "claude" "-p"
                                  "--model" my-hyperspec-model
                                  "--tools" ""
                                  "--no-session-persistence"
                                  "--system-prompt" my-hyperspec-prompt)
                   :coding 'utf-8
                   :connection-type 'pipe
                   :sentinel (lambda (process _event)
                               (unless (process-live-p process)
                                 (my-hyperspec--rewrite-done name process))))))
    (push (cons name process) my-hyperspec--running)
    (process-send-string process (my-hyperspec-html-to-text (my-hyperspec--html-file name)))
    (process-send-eof process)))

(defun my-hyperspec--rewrite-next ()
  "Fill the free job slots from the queue."
  (while (and my-hyperspec--queue
              (< (length my-hyperspec--running) my-hyperspec-jobs))
    (my-hyperspec--rewrite-start (pop my-hyperspec--queue)))
  (when (and (null my-hyperspec--queue) (null my-hyperspec--running))
    (message "my-hyperspec: batch finished")))

;;;###autoload
(defun my-hyperspec-download ()
  "Download the mirror from `my-hyperspec-repo' to `my-hyperspec-cache-dir'.
If the directory is a git clone, update it.  Otherwise, clone into it.
The directory must be new or empty."
  (interactive)
  (let* ((dir my-hyperspec-cache-dir)
         (clone (not (file-directory-p (expand-file-name ".git" dir)))))
    (when (and clone
               (file-directory-p dir)
               (directory-files dir nil directory-files-no-dot-files-regexp))
      (user-error "%s is not empty and is not a git clone" dir))
    (make-directory (file-name-directory (directory-file-name dir)) t)
    (let ((default-directory (if clone
                                 (file-name-directory (directory-file-name dir))
                               dir))
          (process-environment (cons "GIT_TERMINAL_PROMPT=0" process-environment)))
      (message "my-hyperspec: %s the mirror..." (if clone "downloading" "updating"))
      (make-process
       :name "hyperspec-download"
       :buffer (generate-new-buffer " *hyperspec-download*")
       :command (if clone
                    (list "git" "clone" "--depth" "1" my-hyperspec-repo
                          (directory-file-name dir))
                  (list "git" "pull" "--ff-only"))
       :sentinel (lambda (process _event)
                   (unless (process-live-p process)
                     (let ((output (with-current-buffer (process-buffer process)
                                     (string-trim (buffer-string)))))
                       (if (zerop (process-exit-status process))
                           (message "my-hyperspec: mirror ready in %s" dir)
                         (message "my-hyperspec: download failed: %s" output)))
                     (kill-buffer (process-buffer process))))))))

;;;###autoload
(defun my-hyperspec-rewrite-all ()
  "Rewrite all dictionary pages that are not in the mirror."
  (interactive)
  (when my-hyperspec--running
    (user-error "A rewrite batch is already running"))
  (make-directory my-hyperspec-cache-dir t)
  (setq my-hyperspec--queue
        (seq-remove (lambda (name) (file-exists-p (my-hyperspec--mirror-file name)))
                    (my-hyperspec--dictionary-pages))
        my-hyperspec--done 0
        my-hyperspec--total (length my-hyperspec--queue))
  (message "my-hyperspec: %d pages to rewrite" my-hyperspec--total)
  (my-hyperspec--rewrite-next))

(defun my-hyperspec-rewrite-cancel ()
  "Stop the rewrite batch."
  (interactive)
  (setq my-hyperspec--queue nil)
  (dolist (entry my-hyperspec--running)
    (delete-process (cdr entry)))
  (setq my-hyperspec--running nil)
  (message "my-hyperspec: batch cancelled"))

(provide 'my-hyperspec)

;;; my-hyperspec.el ends here
