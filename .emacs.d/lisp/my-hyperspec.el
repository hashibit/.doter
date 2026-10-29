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
;;      Anchors of glossary and chapter pages stay as {#name} markers.
;;   2. It sends the text to the claude CLI.  The CLI writes a small HTML subset.
;;      Dictionary, glossary and chapter pages each have their own prompt.
;;   3. It checks the HTML and the anchors.  It checks the examples (see below).
;;      It adds the Previous, Up and Next links, and saves the page.
;;   It skips pages that are already in the mirror.
;;   `my-hyperspec-rewrite-cancel' stops the batch.
;;
;; A wrong example does more harm than no example.  Step 3 checks them:
;;   - A dictionary page must have the examples of the original page.
;;   - SBCL runs the examples of a chapter or glossary page.  A form that has a
;;     result after => must give that result.  Lisp code is in
;;     my-hyperspec-check.lisp.  SBCL must be installed.
;;   - A link in the form [label](target) is a fault.
;;   A page with a fault goes back to the model with the faults in the prompt.
;;   `my-hyperspec-attempts' sets how many times.  After that, the page is not saved.
;;   `my-hyperspec-check-all' checks all pages in the mirror.
;;   `my-hyperspec-rewrite-failed' rewrites the pages that it found faults in.
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

(defcustom my-hyperspec-attempts 3
  "Number of times that a page can be rewritten, if its examples are wrong.
The model gets the faults in the prompt.  After the last try, the page is
not saved."
  :type 'integer)

(defcustom my-hyperspec-skip-pages '("00_" "01_i")
  "Pages that `my-hyperspec-rewrite-all' does not rewrite.
They are the credits and long lists of names.  eww shows the original page."
  :type '(repeat string))

(defconst my-hyperspec--link-rules
  "Rules for the links:
- The page text has links in the form [label](target).
- Keep each link that fits your new text.  Write it as <a href=\"target\">label</a>.
- Do not change a target.  Do not add a link that is not in the page.
- You may change the label words and move a link to another sentence."
  "Prompt text about links.  All page kinds use it.")

(defconst my-hyperspec--marker-rules
  "Rules for the markers:
- The page text has markers in the form {#name}.  They mark the places that other pages link to.
- Put id=\"name\" on the element that holds the marker.  Use p, h2, li or pre for this element.
- Do not write the marker text in the output.  Do not leave out any marker."
  "Prompt text about markers.  Glossary and chapter pages use it.")

(defun my-hyperspec--format-rules (tags attributes)
  "Return the prompt text about the output format.
TAGS lists the allowed tags.  ATTRIBUTES says which attributes are allowed."
  (format "Rules for the format:
- Output HTML only.  Do not use markdown.  Do not wrap the output in code fences.
- Use only these tags: %s.  Use no attribute except %s.
- Start with one h1 that holds the page title.  Use h2 for the sections.
- Put every code example, call syntax and grammar in pre.
- Write < > and & as &lt; &gt; and &amp; in the text and in pre.
- Output only the page.  Do not add comments about the task."
          tags attributes))

(defconst my-hyperspec-prompt
  (concat
   "You rewrite one page of the Common Lisp HyperSpec for application developers.
The input is the text of the page.  Write the same page as a practical manual.

Rules for the content:
- Use plain and simple English.  Use short sentences.  Use active voice.
- Do not use legal or standards language.  Say what the symbol does and how to use it.
- Keep this order: name and kind, call syntax, what it does, arguments, return values, examples, pitfalls, formal grammar, related symbols.
- Call syntax holds only the short form of the call.  Do not put grammar rules (lines with ::=) in it.
- Move all grammar rules to an h2 named \"Formal grammar\".  Put it before the h2 for related symbols.
- Write the Formal grammar section only if the page has grammar rules.  If it has none, leave it out.  Do not write a sentence about missing rules.
- Put nothing else in the Formal grammar section.  Put a class precedence list in an h2 named \"Class precedence list\".  Put math formulas in an h2 named \"Mathematical definitions\".  Put X3J13 cleanup issues in an h2 named \"Related X3J13 cleanup issues\".  Put these h2 sections before the h2 for related symbols.
- Keep the grammar rules exactly as written.
- Start the Formal grammar section with one sentence that says it is reference material that most readers can skip.
- After that sentence, repeat the forms from the call syntax that use these rules, each in its own pre, with its label such as \"The extended form:\".  Then write the rules in one pre.
- Keep every code example and its output exactly as written.
- Keep all facts.  Do not add behavior that the page does not state.
- Write one clear sentence for each rule about errors and undefined behavior.
- If a page covers many symbols, give each symbol its own section.

"
   my-hyperspec--link-rules "\n\n"
   (my-hyperspec--format-rules "h1, h2, p, ul, li, pre, code, a" "href on a"))
  "System prompt for the rewrite of a dictionary page.")

(defconst my-hyperspec-glossary-prompt
  (concat
   "You rewrite one page of the glossary of the Common Lisp HyperSpec for application developers.
The input is the text of the page.  It is an alphabetical list of terms.
Each entry has a term, a part of speech such as n. or v., and a definition.

Rules for the content:
- Keep every entry, in the same order.  Do not merge entries.  Do not drop entries.
- Keep the term and the part of speech exactly as written.
- Write each definition in plain and simple English.  Use common words.  Use short sentences, one idea in each.  Use active voice.
- Replace a hard word with a common word only when both words mean exactly the same.  For example, write \"stands for\" for \"denotes\", and \"conversion\" for \"coercion\".
- Do not replace a technical term with a looser phrase.  Keep terms such as \"conceptual location\", \"establishment\" and \"extent\" as they are.
- Write \"the consequences are undefined\" as \"the result is undefined: the program may do anything\".
- Keep the meaning exactly.  Keep every condition and every exception.  Do not add facts to the definition.
- Keep numbered meanings (1. 2. 3.), quoted examples, labels such as Trad. or ANSI, and each See or See also reference.
- Keep every symbol name exactly as written, with its * and + characters.

Rules for the extra help:
- After the definition, you may add help for the reader.  The help is not in the standard.
- Write the help in one <i> element at the end of the entry.  Start it with \"(Not in the standard.)\".
- In the help, write one short sentence that starts with \"In short:\" and says the idea in the simplest words.
- When a tiny Lisp example makes the idea clear, add one sentence that starts with \"Example:\", with the code in <code>.  Use only well-known standard Lisp behavior.  Make sure the result that you show is correct.
- If the definition is already clear, add no help.

Rules for the entries:
- Write each entry as <p id=\"name\"><b>term</b> <i>n.</i> definition <i>(Not in the standard.) In short: ... Example: ...</i></p>.
- The input marks the start of each entry with a marker.  Use its name as the id.

"
   my-hyperspec--marker-rules "\n\n"
   my-hyperspec--link-rules "\n\n"
   (my-hyperspec--format-rules "h1, h2, p, ul, li, pre, code, a, b, i"
                               "href on a and id on p, h2, li and pre"))  "System prompt for the rewrite of a glossary page.")

(defconst my-hyperspec-chapter-prompt
  (concat
   "You rewrite one section of the Common Lisp HyperSpec for application developers.
The input is the text of a section of the standard.  Write the same section as a practical guide.

Rules for the content:
- Use plain and simple English.  Use short sentences.  Use active voice.
- Do not use legal or standards language.  Say what a rule means for a programmer.
- Keep the section number and the title in the h1.
- Keep the same order.  Keep a heading for each subsection.
- Keep all facts, rules, limits and numbers.  Do not add behavior that the page does not state.
- Keep every code example, figure, table and list of names exactly as written.
- Keep every symbol name exactly as written, with its * and + characters.
- Say each rule about errors and undefined behavior in one clear sentence.
- When the text uses a term of art that a beginner may not know, add a few plain words the first time it appears.  The link stays.

Rules for the extra help:
- After a section or subsection that is hard to understand without examples, add help for the reader.  The help is not in the standard.
- Put the help in an h2 or h3 named \"Examples (not in the standard)\", one level below the heading of its section.  Put it at the end of that section.
- Give two to five small examples.  Put each example in its own pre.  Before each pre, write one short sentence that says what the example shows.
- For a syntax, show sample strings and the parts that each one has.  For a rule, show Lisp code that follows the rule and the result.
- Use only well-known standard Lisp behavior.  Make sure each result that you show is correct.  Do not show behavior that depends on the implementation.
- Show only valid examples.  Do not show an example that is wrong or that an implementation may accept.
- If the section already has examples, or is a list of names, a table or a figure, add no help.

"
   my-hyperspec--marker-rules "\n\n"
   my-hyperspec--link-rules "\n\n"
   (my-hyperspec--format-rules "h1, h2, h3, p, ul, li, pre, code, a, b, i"
                               "href on a and id on p, h2, h3, li and pre"))
  "System prompt for the rewrite of a chapter or section page.")

(defvar my-hyperspec--feedback (make-hash-table :test #'equal)
  "Table of page name to the text about the faults in the last version.")

(defvar my-hyperspec--attempts (make-hash-table :test #'equal)
  "Table of page name to the number of failed rewrites in the current batch.")

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

(defun my-hyperspec--all-pages ()
  "Return the names of all pages to rewrite.  Skip `my-hyperspec-skip-pages'."
  (seq-remove (lambda (name) (member name my-hyperspec-skip-pages))
              (mapcar #'file-name-sans-extension
                      (directory-files (expand-file-name "Body/" my-hyperspec-root)
                                       nil "\\.htm\\'"))))

(defun my-hyperspec--page-kind (name)
  "Return the kind of page NAME: `glossary', `chapter' or `dictionary'."
  (cond ((string-prefix-p "26_glo_" name) 'glossary)
        ((string-match-p "\\`[0-9][0-9]_" name) 'chapter)
        (t 'dictionary)))

(defun my-hyperspec--prompt (name)
  "Return the system prompt for page NAME.
If the last version of the page had faults, add them to the prompt."
  (concat (pcase (my-hyperspec--page-kind name)
            ('glossary my-hyperspec-glossary-prompt)
            ('chapter my-hyperspec-chapter-prompt)
            (_ my-hyperspec-prompt))
          (when-let* ((faults (gethash name my-hyperspec--feedback)))
            (concat "\n\nThe last version of this page had faults.  Fix them.  Check every example again.
A line that starts with \"Example block\" gives the number of the block, the kind of fault, the form, the result that the page shows (expected) and the real result in SBCL (got).
If you are not sure about a result, remove the example.\n"
                    faults))))

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

(defun my-hyperspec--anchor-names (file)
  "Return the names of the anchors in HTML FILE."
  (let ((dom (with-temp-buffer
               (insert-file-contents file)
               (libxml-parse-html-region (point-min) (point-max)))))
    (delete-dups (delq nil (mapcar (lambda (a)
                                     (and (not (dom-attr a 'href)) (dom-attr a 'name)))
                                   (dom-by-tag dom 'a))))))

(defun my-hyperspec--mark-anchors (dom)
  "Write each anchor in DOM as a {#name} marker.  Return DOM."
  (dolist (a (dom-by-tag dom 'a))
    (when-let* ((name (dom-attr a 'name))
                ((not (dom-attr a 'href))))
      (setf (cddr a) (cons (format "{#%s}" name) (cddr a)))))
  dom)

(defun my-hyperspec-html-to-text (file &optional anchors)
  "Return the text of HTML FILE, as eww shows it.
Links to other HyperSpec pages are written as [label](target).
If ANCHORS is non-nil, anchors are written as {#name} markers."
  (let ((dom (with-temp-buffer
               (insert-file-contents file)
               (libxml-parse-html-region (point-min) (point-max))))
        (shr-use-fonts nil)
        (shr-inhibit-images t)
        (shr-width my-hyperspec-text-width))
    (with-temp-buffer
      (shr-insert-document (my-hyperspec--mark-links
                            (if anchors (my-hyperspec--mark-anchors (my-hyperspec--prune dom))
                              (my-hyperspec--prune dom))))
      (string-trim (buffer-substring-no-properties (point-min) (point-max))))))

;;; Check the examples

(defconst my-hyperspec--checker
  (expand-file-name "my-hyperspec-check.lisp"
                    (file-name-directory (or load-file-name buffer-file-name)))
  "Lisp script that runs the examples of a page in SBCL.")

(defconst my-hyperspec--markdown-link-regexp
  "\\[\\([^]\n]*\\)\\](\\([^) \n]*\\.htm[^) \n]*\\))"
  "Regexp for a link in the form [label](target.htm).")

(defconst my-hyperspec--result-regexp
  (concat "\\` \\(?:returns\\|evaluates to\\|yields\\|has the value\\|the result is\\) "
          "\\(.+?\\)\\(?: \\(?:and\\|because\\|in\\|so\\|which\\)\\_>\\|[.,;]\\(?: \\|\\'\\)\\)")
  "Regexp for the result that a glossary example gives after its form.")

(define-error 'my-hyperspec-fixable "The page has faults" 'error)

(defun my-hyperspec--pre-text (node)
  "Return the code in the pre element NODE.  Write each arrow as =>."
  (let ((text (replace-regexp-in-string my-hyperspec--markdown-link-regexp "\\1"
                                        (dom-inner-text node))))
    (setq text (replace-regexp-in-string ";+[ \t]*\\(?:=>\\|→\\|==>\\)" "=>" text))
    (replace-regexp-in-string "\\(\\`\\|[^[:word:]\"]\\)\\(?:→\\|==>\\)\\([ \t\n]\\)" "\\1=>\\2" text)))

(defun my-hyperspec--section-blocks (dom heading)
  "Return the code in the pre elements of DOM that follow a heading.
HEADING is a regexp for the text of the heading.  The section ends at the next
h2 or h3 heading."
  (let (in blocks)
    (named-let walk ((node dom))
      (when (consp node)
        (pcase (dom-tag node)
          ((or 'h2 'h3) (setq in (string-match-p heading (dom-inner-text node))))
          ('pre (when in (push (my-hyperspec--pre-text node) blocks)))
          (_ (dolist (child (dom-non-text-children node))
               (walk child))))))
    (nreverse blocks)))

(defun my-hyperspec--glossary-blocks (dom)
  "Return one code block for each example in the glossary page DOM.
An example is a code form in an i element that has \"Example:\".
If the text after the form says what it returns, the block has that result
after =>."
  (let (blocks)
    (dolist (node (dom-by-tag dom 'i))
      (let ((text (dom-inner-text node))
            (pos 0)
            lines)
        (when (string-match-p "Example:" text)
          (dolist (code (dom-by-tag node 'code))
            (let ((form (dom-inner-text code)))
              (when (and (string-match-p "\\`\\(?:(\\|'\\|#'\\)" form)
                         (string-match (regexp-quote form) text pos))
                (setq pos (match-end 0))
                (let ((rest (substring text pos)))
                  (push (if (string-match my-hyperspec--result-regexp rest)
                            (concat form " => " (match-string 1 rest))
                          form)
                        lines)))))
          (when lines
            (push (string-join (nreverse lines) "\n") blocks)))))
    (nreverse blocks)))

(defun my-hyperspec--sbcl-problems (blocks)
  "Run the code BLOCKS in SBCL.  Return a list of texts about the wrong examples.
A form that has a result after => must give that result."
  (when blocks
    (unless (executable-find "sbcl")
      (error "Cannot check the examples: sbcl is not installed"))
    (let* ((coding-system-for-read 'utf-8)
           (coding-system-for-write 'utf-8)
           (file (make-temp-file "hyperspec-check" nil ".txt" (string-join blocks "\f")))
           (default-directory (file-name-as-directory (make-temp-file "hyperspec-run" t)))
           problems)
      (unwind-protect
          (with-temp-buffer
            (let ((status (call-process "sbcl" nil t nil "--script" my-hyperspec--checker file)))
              (unless (eq status 0)
                (push (format "The check of the examples stopped: %s"
                              (truncate-string-to-width (string-trim (buffer-string)) 300))
                      problems))
              (goto-char (point-min))
              (while (re-search-forward
                      "^\\([0-9]+\\) \\(MISMATCH\\|ERROR\\|UNBALANCED\\)\\(?: | \\(.*\\)\\)?$" nil t)
                (push (format "Example block %s: %s | %s" (match-string 1) (match-string 2)
                              (or (match-string 3) ""))
                      problems))))
        (delete-file file)
        (delete-directory default-directory t))
      (nreverse problems))))

(defun my-hyperspec--flat (text)
  "Return TEXT in a form that makes it easy to compare two examples.
The result has no white space and no link syntax.  Each arrow is =>."
  (let ((text (replace-regexp-in-string "[[:space:] ]+" "" text)))
    (setq text (replace-regexp-in-string "\\[\\([^]]*\\)\\]([^)]*)" "\\1" text))
    (replace-regexp-in-string ";+=>\\|→\\|==>" "=>" text)))

(defun my-hyperspec--fidelity-problems (dom name)
  "Return texts about the examples in DOM that are not in the original page NAME.
The examples of a dictionary page come from the standard.
They stay as they are."
  (let ((original (my-hyperspec--flat
                   (my-hyperspec-html-to-text (my-hyperspec--html-file name)))))
    (cl-loop for block in (my-hyperspec--section-blocks dom "\\`Examples\\'")
             unless (string-search (my-hyperspec--flat block) original)
             collect (format "This example block is not in the original page.  Copy the examples of the page exactly, or leave the section out:\n%s"
                             (truncate-string-to-width (string-trim block) 300)))))

(defun my-hyperspec--page-problems (html name)
  "Return a list of texts about the faults in HTML, the mirror page NAME.
The faults are links in markdown form and wrong examples."
  (let ((dom (with-temp-buffer
               (insert html)
               (libxml-parse-html-region (point-min) (point-max)))))
    (append
     (when (string-match-p "<\\(?:[^A-Za-z/!]\\|\\'\\)" html)
       (list "The page has a < that does not start a tag.  Write < as &lt; in the text and in pre."))
     (when (string-match-p my-hyperspec--markdown-link-regexp html)
       (list "The page has a link in the form [label](target).  Write every link as <a href=\"target\">label</a>.  Do this in pre too."))
     (pcase (my-hyperspec--page-kind name)
       ('dictionary (my-hyperspec--fidelity-problems dom name))
       ('chapter (my-hyperspec--sbcl-problems
                  (my-hyperspec--section-blocks dom "Examples (not in the standard)")))
       ('glossary (my-hyperspec--sbcl-problems (my-hyperspec--glossary-blocks dom)))))))

;;;###autoload
(defun my-hyperspec-check-all ()
  "Check the examples and the links of all pages in the mirror.
Dictionary pages must have the examples of the original.  Chapter and glossary
examples must give the results that they show, when SBCL runs them.
Save the faults for `my-hyperspec-rewrite-failed'.  Show the pages that have
faults."
  (interactive)
  (clrhash my-hyperspec--feedback)
  (let ((coding-system-for-read 'utf-8)
        (pages (mapcar #'file-name-sans-extension
                       (directory-files (expand-file-name "Body/" my-hyperspec-cache-dir)
                                        nil "\\.htm\\'"))))
    (dolist (name pages)
      (when-let* ((problems (my-hyperspec--page-problems
                             (with-temp-buffer
                               (insert-file-contents (my-hyperspec--mirror-file name))
                               (buffer-string))
                             name)))
        (puthash name (string-join problems "\n") my-hyperspec--feedback)
        (message "my-hyperspec: %s has %d faults" name (length problems)))))
  (with-current-buffer (get-buffer-create "*my-hyperspec-check*")
    (erase-buffer)
    (maphash (lambda (name faults) (insert name "\n" faults "\n\n")) my-hyperspec--feedback)
    (goto-char (point-min))
    (display-buffer (current-buffer)))
  (message "my-hyperspec: %d pages have faults" (hash-table-count my-hyperspec--feedback)))

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

(defconst my-hyperspec--allowed-tags
  '(html head body meta title h1 h2 h3 h4 p ul ol li dl dt dd pre code a b i em strong
         sup sub br hr blockquote table thead tbody tr th td)
  "Tags that a mirror page may have.
The first four are the tags that the HTML parser adds around a fragment.")

(defun my-hyperspec--unknown-tags (dom)
  "Return the tag names in DOM that `my-hyperspec--allowed-tags' does not list.
A raw < in the text, such as <no values>, or a typo in a tag gives such a tag."
  (delete-dups
   (mapcar (lambda (node) (symbol-name (dom-tag node)))
           (dom-search dom (lambda (node)
                             (not (memq (dom-tag node) my-hyperspec--allowed-tags)))))))

(defun my-hyperspec--make-page (output name anchors)
  "Check the HTML in OUTPUT.  Return it as a complete page for page NAME.
ANCHORS are the anchor names of the original page.
Each one needs an id in OUTPUT.
Signal an error if the HTML is bad."
  (let* ((body (string-trim
                (replace-regexp-in-string "\\`[ \t\n]*```[a-z]*\n\\|\n```[ \t\n]*\\'" "" output)))
         (dom (with-temp-buffer
                (insert body)
                (libxml-parse-html-region (point-min) (point-max))))
         (h1 (car (dom-by-tag dom 'h1))))
    (unless h1
      (error "No h1 in the output"))
    (unless (string-suffix-p ">" body)
      (error "The output looks cut off"))
    (when-let* ((missing (seq-remove
                          (lambda (anchor)
                            (dom-search dom (lambda (node) (equal (dom-attr node 'id) anchor))))
                          anchors)))
      (error "Anchors missing in the output: %s" (string-join (seq-take missing 5) " ")))
    (when-let* ((unknown (my-hyperspec--unknown-tags dom)))
      (error "Unknown tags in the output: %s" (string-join (seq-take unknown 5) " ")))
    (when-let* ((problems (my-hyperspec--page-problems body name)))
      (signal 'my-hyperspec-fixable (list (string-join problems "\n"))))
    (let ((nav (or (my-hyperspec--nav name) "")))
      (format "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<title>%s</title>\n</head>\n<body>\n%s\n<hr>\n%s\n<hr>\n%s\n</body>\n</html>\n"
              (xml-escape-string (string-trim (dom-inner-text h1)))
              nav body nav))))

(defun my-hyperspec--rewrite-done (name process)
  "Save the output of PROCESS as the mirror page NAME.  Then start the next page."
  (setq my-hyperspec--running (assq-delete-all name my-hyperspec--running))
  (let ((output (with-current-buffer (process-buffer process)
                  (string-trim (buffer-string))))
        (retry nil))
    (condition-case err
        (progn
          (unless (and (zerop (process-exit-status process)) (not (string-empty-p output)))
            (error "claude failed: %s" output))
          (let ((file (my-hyperspec--mirror-file name))
                (coding-system-for-write 'utf-8))
            (make-directory (file-name-directory file) t)
            (write-region (my-hyperspec--make-page output name (process-get process 'anchors)) nil file nil 'silent)
            (remhash name my-hyperspec--feedback)))
      (my-hyperspec-fixable
       (let ((tries (puthash name (1+ (gethash name my-hyperspec--attempts 0))
                             my-hyperspec--attempts)))
         (puthash name (cadr err) my-hyperspec--feedback)
         (setq retry (< tries my-hyperspec-attempts))
         (message "my-hyperspec: %s has faults (try %d of %d)%s:\n%s" name tries my-hyperspec-attempts
                  (if retry "" ", page not saved") (cadr err))))
      (error (message "my-hyperspec: rewrite of %s failed: %s" name (error-message-string err))))
    (kill-buffer (process-buffer process))
    (if retry
        (push name my-hyperspec--queue)
      (cl-incf my-hyperspec--done)))
  (message "my-hyperspec: %d/%d pages rewritten" my-hyperspec--done my-hyperspec--total)
  (my-hyperspec--rewrite-next))

(defun my-hyperspec--rewrite-start (name)
  "Start the rewrite of page NAME."
  (let* ((default-directory my-hyperspec-cache-dir)
         (file (my-hyperspec--html-file name))
         (marked (not (eq (my-hyperspec--page-kind name) 'dictionary)))
         (process (make-process
                   :name (concat "hyperspec-" name)
                   :buffer (generate-new-buffer (format " *hyperspec-%s*" name))
                   :command (list "claude" "-p"
                                  "--model" my-hyperspec-model
                                  "--tools" ""
                                  "--no-session-persistence"
                                  "--system-prompt" (my-hyperspec--prompt name))
                   :coding 'utf-8
                   :connection-type 'pipe
                   :sentinel (lambda (process _event)
                               (unless (process-live-p process)
                                 (my-hyperspec--rewrite-done name process))))))
    (push (cons name process) my-hyperspec--running)
    (when marked
      (process-put process 'anchors (my-hyperspec--anchor-names file)))
    (process-send-string process (my-hyperspec-html-to-text file marked))
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
  "Rewrite all pages that are not in the mirror."
  (interactive)
  (when my-hyperspec--running
    (user-error "A rewrite batch is already running"))
  (make-directory my-hyperspec-cache-dir t)
  (clrhash my-hyperspec--attempts)
  (setq my-hyperspec--queue
        (seq-remove (lambda (name) (file-exists-p (my-hyperspec--mirror-file name)))
                    (my-hyperspec--all-pages))
        my-hyperspec--done 0
        my-hyperspec--total (length my-hyperspec--queue))
  (message "my-hyperspec: %d pages to rewrite" my-hyperspec--total)
  (my-hyperspec--rewrite-next))

;;;###autoload
(defun my-hyperspec-rewrite-failed ()
  "Rewrite the pages that have faults.
Run `my-hyperspec-check-all' first.  It saves the faults.  The model gets them
in the prompt.  This also rewrites the pages that are not in the mirror."
  (interactive)
  (dolist (name (hash-table-keys my-hyperspec--feedback))
    (let ((file (my-hyperspec--mirror-file name)))
      (when (file-exists-p file)
        (delete-file file))))
  (my-hyperspec-rewrite-all))

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
