;;suppress any package cl warnings
(setq byte-compile-warnings '(cl-functions))

;;package and use-package

(require 'package)
(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/") t)
;;(package-initialize)
;;(unless package--initialized (package-initialize t))
(when (version< emacs-version "27.0") (package-initialize))

;; Bootstrap 'use-package'
(eval-after-load 'gnutls
  '(add-to-list 'gnutls-trustfiles "/etc/ssl/cert.pem"))
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))
(require 'bind-key)
(setq use-package-always-ensure t)

;;-list the repositories containing them
(setq package-archives '(("melpa" . "http://melpa.org/packages/")
                         ("elpa" . "http://tromey.com/elpa/")
                         ("gnu" . "http://elpa.gnu.org/packages/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")))


;;-install the missing packages
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(setq use-package-always-ensure t)

(setq byte-compile-warnings '(cl-functions))
;;-activate all the packages (in particular autoloads)
(package-initialize)
(require 'package)

;;function to auto-download a list of packages\
;;-list the packages you want
(use-package pabbrev
  :ensure t)
(use-package solarized-theme
  :ensure t)
(if (display-graphic-p)
    (use-package moody
      :ensure t))
(use-package synosaurus
  :ensure t)
(use-package org
  :ensure t)
(use-package diff-hl
  :ensure t)
(use-package org-bullets
  :ensure t)
(use-package latex-pretty-symbols
  :ensure t)
;;(use-package flyspell
;;  :ensure t)
(use-package minions
  :ensure t)
(use-package htmlize
  :ensure t)
(use-package ox-twbs
  :ensure t)
(use-package html-check-frag
  :ensure t)
(use-package multi-term
  :ensure t)
;;(use-package eshell-fringe-status
;;  :ensure t)


;; If use-package isn't already installed, it's extremely likely that this is a
;; fresh installation! So we'll want to update the package repository and
;; install use-package before loading the literate configuration.
;;(when (not (package-installed-p 'use-package))
;;(package-refresh-contents)
;;(package-install 'use-package))

;;function to save macros
(defun save-macro (name)
    "save a macro. Take a name as argument
     and save the last defined macro under
     this name at the end of your .emacs"
     (interactive "SName of the macro: ")  ; ask for the name of the macro
     (kmacro-name-last-macro name)         ; use this name for the macro
     (find-file user-init-file)            ; open ~/.emacs or other user init file
     (goto-char (point-max))               ; go to the end of the .emacs
     (newline)                             ; insert a newline
     (insert-kbd-macro name)               ; copy the macro
     (newline)                             ; insert a newline
     (save-buffer)                         ; save buffery
     (switch-to-buffer nil))               ; switch back to original buffer

(fset 'removeline
      (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ([1 11 backspace 14] 0 "%d")) arg)))

;;load org config file
(org-babel-load-file "~/.emacs.d/org/config.org")

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files
   '("~/Dropbox/orgdocs/amazon/work.org" "~/Dropbox/orgdocs/taskdiary.org"))
 '(package-selected-packages
   '(lua-mode web-mode-edit-element web-search web-server poly-ansible html-check-frag org-ac magit live-preview diff-hl use-package synosaurus solarized-theme pabbrev org-bullets moody minions latex-pretty-symbols gnuplot auto-compile)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(show-paren-match ((t (:foreground "light green" :weight bold)))))
