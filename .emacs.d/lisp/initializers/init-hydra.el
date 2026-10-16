;;; -*- lexical-binding: t -*-

;; Have to use require, not use-package
(require 'hydra)
(defhydra undo-tree-menu (global-map "C-c u") "
_u_: undo      _r_: redo
"
  ("u" undo-tree-undo) ("r" undo-tree-redo))

(defhydra hydra-cw-o-window-menu (global-map "C-c C-w") "
_o_: other-window
"
  ("o" other-window))



(provide 'init-hydra)
