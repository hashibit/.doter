;; -*- lexical-binding: t -*-
;;; init-impatient-markdown.el --- Impatient-mode Markdown preview

;; render like github

;;; Code:

(defun my-markdown-html-github (buffer)
  (princ
   (with-current-buffer buffer
     (format
      "<!DOCTYPE html><html><script src=\"https://cdnjs.cloudflare.com/ajax/libs/he/1.1.1/he.js\"></script><link rel=\"stylesheet\" href=\"https://assets-cdn.github.com/assets/github-e6bb18b320358b77abe040d2eb46b547.css\"><link rel=\"stylesheet\" href=\"https://assets-cdn.github.com/assets/frameworks-95aff0b550d3fe338b645a4deebdcb1b.css\"><title>Impatient Markdown</title><div id=\"markdown-content\" style=\"display:none\">%s</div><div class=\"markdown-body\" style=\"max-width:968px;margin:0 auto;\"></div><script>fetch('https://api.github.com/markdown', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ \"text\": document.getElementById('markdown-content').innerHTML, \"mode\": \"gfm\", \"context\": \"knit-pk/homepage-nuxtjs\"}) }).then(response => response.text()).then(response => {document.querySelector('.markdown-body').innerHTML = he.decode(response)}).then(() => { fetch(\"https://gist.githubusercontent.com/FieryCod/b6938b29531b6ec72de25c76fa978b2c/raw/\").then(response => response.text()).then(eval)});</script></html>"
      (buffer-substring-no-properties (point-min) (point-max))))
   (current-buffer)))

(defun my-markdown-html (buffer)
  (princ
   (with-current-buffer buffer
     (format
      "<!DOCTYPE html><html><title>Impatient Markdown</title><xmp theme=\"united\" style=\"display:none;\"> %s  </xmp><script src=\"http://ndossougbe.github.io/strapdown/dist/strapdown.js\"></script></html>"
      (buffer-substring-no-properties (point-min) (point-max))))
   (current-buffer)))

(declare-function imp-set-user-filter "impatient-mode")

(defun my-impatient-markdown-setup ()
  (impatient-mode 1)
  (imp-set-user-filter #'my-markdown-html-github))

(use-package impatient-mode
  :config
  (add-hook 'markdown-mode-hook #'my-impatient-markdown-setup))


(provide 'init-impatient-markdown)

;;; init-impatient-markdown.el ends here
