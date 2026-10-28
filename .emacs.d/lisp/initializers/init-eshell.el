;; -*- lexical-binding: t -*-
;;; init-eshell.el --- Eshell and comint configuration

;; eshell with colors
;; SEE https://emacs.stackexchange.com/questions/51027/missing-color-support-for-exa-in-eshell

;;; Code:

(setq comint-terminfo-terminal "dumb-emacs-ansi")

(let* ((terminfo-file (format "~/.terminfo/%s.ti" comint-terminfo-terminal))
       (default-directory (file-name-directory terminfo-file)))
  (unless (file-exists-p terminfo-file)
    (make-directory default-directory t)
    (with-temp-buffer
      (insert
       "dumb-emacs-ansi|Emacs dumb terminal with ANSI color codes,
    am,
    colors#8, it#8, ncv#13, pairs#64,
    bold=\\E[1m, cud1=^J, ht=^I, ind=^J, op=\\E[39;49m,
    ritm=\\E[23m, rmul=\\E[24m, setab=\\E[4%p1%dm,
    setaf=\\E[3%p1%dm, sgr0=\\E[m, sitm=\\E[3m, smul=\\E[4m,")
      (write-file terminfo-file)))
  (unless (file-exists-p (concat default-directory "d/" comint-terminfo-terminal))
    (start-process "*tic process*" "*Messages*" "tic"
                   (expand-file-name terminfo-file))))

(defun my-eshell-setup-env ()
  (setenv "TERM" comint-terminfo-terminal)
  (setenv "PAGER" "cat"))

(add-hook 'eshell-mode-hook #'my-eshell-setup-env)



(provide 'init-eshell)

;;; init-eshell.el ends here
