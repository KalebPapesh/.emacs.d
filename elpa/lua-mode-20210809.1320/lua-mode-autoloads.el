;;; lua-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "lua-mode" "../../../../../../home/papkaleb/.emacs.d/elpa/lua-mode-20210809.1320/lua-mode.el"
;;;;;;  "44d767c8030ec91f2c8768c4642b8699")
;;; Generated autoloads from ../../../../../../home/papkaleb/.emacs.d/elpa/lua-mode-20210809.1320/lua-mode.el

(autoload 'lua-mode "lua-mode" "\
Major mode for editing Lua code.

\(fn)" t nil)

(add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-mode))

(add-to-list 'interpreter-mode-alist '("lua" . lua-mode))

(defalias 'run-lua #'lua-start-process)

(autoload 'lua-start-process "lua-mode" "\
Start a Lua process named NAME, running PROGRAM.
PROGRAM defaults to NAME, which defaults to `lua-default-application'.
When called interactively, switch to the process buffer.

\(fn &optional NAME PROGRAM STARTFILE &rest SWITCHES)" t nil)

;;;### (autoloads "actual autoloads are elsewhere" "lua-mode" "../../../../../../home/papkaleb/.emacs.d/elpa/lua-mode-20210809.1320/lua-mode.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from ../../../../../../home/papkaleb/.emacs.d/elpa/lua-mode-20210809.1320/lua-mode.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "lua-mode" '("lua-")))

;;;***

;;;***

;;;### (autoloads nil nil ("../../../../../../home/papkaleb/.emacs.d/elpa/lua-mode-20210809.1320/lua-mode-autoloads.el"
;;;;;;  "../../../../../../home/papkaleb/.emacs.d/elpa/lua-mode-20210809.1320/lua-mode.el")
;;;;;;  (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; lua-mode-autoloads.el ends here
