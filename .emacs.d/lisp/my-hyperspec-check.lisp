;;; my-hyperspec-check.lisp --- Run the examples of a mirror page in SBCL

;; Usage: sbcl --script my-hyperspec-check.lisp FILE
;;
;; FILE holds code blocks.  Form feed characters separate the blocks.
;; A block is a list of forms.  A form can be followed by "=> RESULT".
;; The script runs the forms and compares each value with its RESULT.
;;
;; Each line of the output is: BLOCK-NUMBER STATUS | DETAIL | ...
;; STATUS is one of these:
;;   OK         the value is the same as the result on the page.
;;   MISMATCH   the value is not the same as the result on the page.
;;   ERROR      the form has a result on the page, but it signals an error.
;;   UNMARKED   the form signals an error, but the page does not show
;;              "=> error" after it.  An example of an error must show it.
;;   UNCHECKED  the result is words or something that the reader cannot read.
;;              A word alone, such as STREAM in "stream => position", is not
;;              checked either.
;;   UNBALANCED the block has a form with a missing parenthesis.

(defpackage :my-hyperspec-check (:use :cl))
(in-package :my-hyperspec-check)

(defun slurp (file)
  (with-open-file (in file :external-format :utf-8)
    (let ((text (make-string (file-length in))))
      (subseq text 0 (read-sequence text in)))))

(defun split-blocks (text)
  (loop with start = 0
        for end = (position #\Page text :start start)
        collect (subseq text start end)
        while end
        do (setf start (1+ end))))

(defun report (block status &rest items)
  (format t "~d ~a~{ | ~a~}~%" block status
          (mapcar (lambda (item)
                    (let ((text (remove #\Newline (prin1-to-string item))))
                      (if (> (length text) 200) (subseq text 0 200) text)))
                  items)))

(defun word-p (form name)
  (and (symbolp form) (string= (symbol-name form) name)))

(defun same-p (value expected)
  "True if VALUE is the result that the page shows as EXPECTED."
  (cond ((word-p expected "TRUE") (and value t))
        ((word-p expected "FALSE") (null value))
        ((and (pathnamep value) (pathnamep expected))
         (equal (file-namestring value) (file-namestring expected)))
        (t (or (equalp value expected)
               (string= (prin1-to-string value) (prin1-to-string expected))))))

(defun run (form)
  "Return (:ok VALUE) or (:err TEXT UNBOUND-VARIABLE-P).
An error that no handler takes ends the form.  A condition that SIGNAL sends and
that no handler takes does not end it.  This is the same as in the REPL."
  (catch 'failed
    (let ((sb-ext:*invoke-debugger-hook*
            (lambda (condition hook)
              (declare (ignore hook))
              (throw 'failed
                (list :err (remove #\Newline (princ-to-string condition))
                      (typep condition 'unbound-variable)))))
          (*standard-output* (make-broadcast-stream))
          (*error-output* (make-broadcast-stream))
          (*standard-input* (make-string-input-stream "")))
      (sb-ext:with-timeout 5
        (list :ok (car (multiple-value-list (eval form))))))))

(defun read-forms (text)
  "Return the forms in TEXT.  Return :incomplete if the last form is not closed."
  (handler-case
      (with-input-from-string (in text)
        (loop for form = (read in nil in)
              until (eq form in)
              collect form))
    (end-of-file () :incomplete)
    (error () :unreadable)))

(defun read-expected (in)
  "Read the result after => from the string stream IN.
Return the form, or :unchecked if the result is words or cannot be read."
  (let* ((start (file-position in))
         (line (read-line in nil ""))
         (line (string-trim (list #\Space #\Tab) (subseq line 0 (search " ;" line))))
         (forms (if (string= line "") '() (read-forms line))))
    (cond ((eq forms :incomplete)
           (file-position in start)
           (handler-case (read in)
             (error () :unchecked)))
          ((eq forms :unreadable) :unchecked)
          ((null forms)
           (handler-case (read in)
             (error () :unchecked)))
          ((cdr forms) :unchecked)
          (t (car forms)))))

(defun check-block (number text)
  (let ((*package* (find-package "COMMON-LISP-USER"))
        (*read-default-float-format* 'single-float)
        (in (make-string-input-stream text))
        (previous nil)
        (last nil))
    (flet ((flush ()
             ;; Report an error of the last form, if no result followed it.
             (when (and (eq (car last) :err) (not (and (symbolp previous) (caddr last))))
               (report number :unmarked previous (cadr last)))))
    (loop
      (let ((form (handler-case (read in nil in)
                    (end-of-file ()
                      (return (report number :unbalanced previous)))
                    (error ()
                      (return (report number :unchecked previous))))))
        (when (eq form in) (flush) (return))
        (cond
          ((word-p form "=>")
           (let ((expected (read-expected in)))
             (cond ((or (eq expected :unchecked) (null last))
                    (report number :unchecked previous))
                   ((and (eq (car last) :err) (symbolp previous) (caddr last))
                    (report number :unchecked previous))
                   ((and (eq (car last) :err) (word-p expected "ERROR"))
                    (report number :ok))
                   ((eq (car last) :err)
                    (report number :error previous (cadr last)))
                   ((same-p (cadr last) expected) (report number :ok))
                   (t (report number :mismatch previous
                              "expected" expected "got" (cadr last))))
             (setf last nil)))
          (t (flush)
             (setf previous form
                   last (run form)))))))))

;; CL-USER in SBCL uses other packages, such as SB-ALIEN.  An example can
;; define a function with the name DOUBLE.  Use only COMMON-LISP, as the standard says.
(unuse-package (remove (find-package "COMMON-LISP") (package-use-list "COMMON-LISP-USER"))
               "COMMON-LISP-USER")

(let ((number 0))
  (dolist (text (split-blocks (slurp (second sb-ext:*posix-argv*))))
    (check-block (incf number) text)))
