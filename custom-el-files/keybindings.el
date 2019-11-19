;;set global key bindings
(global-set-key (kbd "C-x C-j") 'skk-mode) ;;japanese input mode
(global-set-key (kbd "C-x C-b") 'ibuffer) ;;bind ibuffer instead of menu-bar-mode

;;general
(global-set-key (kbd "M-/") 'comment-or-uncomment-region)

;;window sizing
(global-set-key (kbd "C-c w e") 'embiggen-window)
(global-set-key (kbd "C-c w E") 'emsmallen-window)

;;whitespace
(global-set-key (kbd "C-c d w") 'whack-whitespace)
