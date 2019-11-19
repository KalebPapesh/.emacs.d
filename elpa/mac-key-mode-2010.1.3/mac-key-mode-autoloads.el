;;; mac-key-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "mac-key-mode" "mac-key-mode.el" (0 0 0 0))
;;; Generated autoloads from mac-key-mode.el

(defvar mac-key-mode nil "\
Non-nil if Mac-Key mode is enabled.
See the `mac-key-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `mac-key-mode'.")

(custom-autoload 'mac-key-mode "mac-key-mode" nil)

(autoload 'mac-key-mode "mac-key-mode" "\
Toggle Mac Key mode.
With arg, turn Mac Key mode on if arg is positive.
When Mac Key mode is enabled, mac-style key bindings are provided.

\(fn &optional ARG)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "mac-key-mode" '("mode-line-mode-menu" "mac-key-")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; mac-key-mode-autoloads.el ends here
