;; Set up the Correct Path

;;     Need the correct PATH even if we start Emacs from the GUI:


(setenv "PATH"
        (concat
         "/usr/local/bin:/usr/local/sbin:"
         (getenv "PATH")))

;; Pager Setup

;;    If any program wants to pause the output through the =$PAGER=
;;    variable, well, we don't really need that:


(setenv "PAGER" "cat")

;; Configuration

;;   Scrolling through the output and searching for results that can be
;;   copied to the kill ring is a great feature of Eshell. However,
;;   instead of running =end-of-buffer= key-binding, the following
;;   setting means any other key will jump back to the prompt:


(use-package eshell
  :init
  (setq ;; eshell-buffer-shorthand t ...  Can't see Bug#19391
        eshell-scroll-to-bottom-on-input 'all
        eshell-error-if-no-glob t
        eshell-hist-ignoredups t
        eshell-save-history-on-exit t
        eshell-prefer-lisp-functions nil
        eshell-destroy-buffer-when-process-dies t))

;; Visual Executables

;;   Eshell would get somewhat confused if I ran the following commands
;;   directly through the normal Elisp library, as these need the better
;;   handling of ansiterm:


(use-package eshell
  :init
  (add-hook 'eshell-mode-hook
            (lambda ()
              (add-to-list 'eshell-visual-commands "ssh")
              (add-to-list 'eshell-visual-commands "tail")
              (add-to-list 'eshell-visual-commands "top"))))

;; Aliases

;;   Gotta have some [[http://www.emacswiki.org/emacs/EshellAlias][shell aliases]], right?


(add-hook 'eshell-mode-hook (lambda ()
    (eshell/alias "e" "find-file $1")
    (eshell/alias "ff" "find-file $1")
    (eshell/alias "emacs" "find-file $1")
    (eshell/alias "ee" "find-file-other-window $1")

    (eshell/alias "gd" "magit-diff-unstaged")
    (eshell/alias "gds" "magit-diff-staged")
    (eshell/alias "d" "dired $1")

    ;; The 'ls' executable requires the Gnu version on the Mac
    (let ((ls (if (file-exists-p "/usr/local/bin/gls")
                  "/usr/local/bin/gls"
                "/bin/ls")))
      (eshell/alias "ll" (concat ls " -AlohG --color=always")))))

;; Git

;;    My =gst= command is just an alias to =magit-status=, but using the
;;    =alias= doesn't pull in the current working directory, so I make it
;;    a function, instead:


(defun eshell/gst (&rest args)
    (magit-status (pop args) nil)
    (eshell/echo))   ;; The echo command suppresses output

;; Find File

;;    We should have an "f" alias for searching the current directory for
;;    a file, and a "ef" for editing that file.


(defun eshell/f (filename &optional dir try-count)
  "Searches for files matching FILENAME in either DIR or the
current directory. Just a typical wrapper around the standard
`find' executable.

Since any wildcards in FILENAME need to be escaped, this wraps the shell command.

If not results were found, it calls the `find' executable up to
two more times, wrapping the FILENAME pattern in wildcat
matches. This seems to be more helpful to me."
  (let* ((cmd (concat
               (executable-find "find")
               " " (or dir ".")
               "      -not -path '*/.git*'"
               " -and -not -path '*node_modules*'"
               " -and -not -path '*classes*'"
               " -and "
               " -type f -and "
               "-iname '" filename "'"))
         (results (shell-command-to-string cmd)))

    (if (not (s-blank-str? results))
        results
      (cond
       ((or (null try-count) (= 0 try-count))
        (eshell/f (concat filename "*") dir 1))
       ((or (null try-count) (= 1 try-count))
        (eshell/f (concat "*" filename) dir 2))
       (t "")))))

(defun eshell/ef (filename &optional dir)
  "Searches for the first matching filename and loads it into a
file to edit."
  (let* ((files (eshell/f filename dir))
         (file (car (s-split "\n" files))))
    (find-file file)))



;; Typing =find= in Eshell runs the =find= function, which doesn’t do
;; what I expect, and creating an alias is ineffective in overriding
;; it, so a function will do:


(defun eshell/find (&rest args)
  "Wrapper around the ‘find’ executable."
  (let ((cmd (concat "find " (string-join args))))
    (shell-command-to-string cmd)))

;; Clear

;;    While deleting and recreating =eshell= may be just as fast, I always
;;    forget and type =clear=, so let's implement it:


(defun eshell/clear ()
  "Clear the eshell buffer."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (eshell-send-input)))



;; To extend Eshell, we need a two-part function.
;; 1. Parse the Eshell buffer to look for the parameter
;;    (and move the point past the parameter).
;; 2. A predicate function that takes a file as a parameter.

;; For the first step, we have our function /called/ as it helps
;; parse the text at this time.  Based on what it sees, it returns
;; the predicate function used to filter the files:


(defun eshell-org-file-tags ()
  "Helps the eshell parse the text the point is currently on,
looking for parameters surrounded in single quotes. Returns a
function that takes a FILE and returns nil if the file given to
it doesn't contain the org-mode #+TAGS: entry specified."

  (if (looking-at "'\\([^)']+\\)'")
      (let* ((tag (match-string 1))
             (reg (concat "^#\\+TAGS:.* " tag "\\b")))
        (goto-char (match-end 0))

        `(lambda (file)
           (with-temp-buffer
             (insert-file-contents file)
             (re-search-forward ,reg nil t 1))))
    (error "The `T' predicate takes an org-mode tag value in single quotes.")))



;; Add it to the =eshell-predicate-alist= as the =T= tag:


(add-hook 'eshell-pred-load-hook (lambda ()
  (add-to-list 'eshell-predicate-alist '(?T . (eshell-org-file-tags)))))

;; Special Prompt

;;   Following [[http://blog.liangzan.net/blog/2012/12/12/customizing-your-emacs-eshell-prompt/][these instructions]], we build a better prompt with the Git
;;   branch in it (Of course, it matches my Bash prompt). First, we need
;;   a function that returns a string with the Git branch in it,
;;   e.g. ":master"


(defun curr-dir-git-branch-string (pwd)
  "Returns current git branch as a string, or the empty string if
PWD is not in a git repo (or the git command is not found)."
  (interactive)
  (when (and (not (file-remote-p pwd))
             (eshell-search-path "git")
             (locate-dominating-file pwd ".git"))
    (let* ((git-url (shell-command-to-string "git config --get remote.origin.url"))
           (git-repo (file-name-base (s-trim git-url)))
           (git-output (shell-command-to-string (concat "git rev-parse --abbrev-ref HEAD")))
           (git-branch (s-trim git-output))
           (git-icon  "\xe0a0")
           (git-icon2 (propertize "\xf020" 'face `(:family "octicons"))))
      (concat git-repo " " git-icon2 " " git-branch))))



;; The function takes the current directory passed in via =pwd= and
;; replaces the =$HOME= part with a tilde. I'm sure this function
;; already exists in the eshell source, but I didn't find it...


(defun pwd-replace-home (pwd)
  "Replace home in PWD with tilde (~) character."
  (interactive)
  (let* ((home (expand-file-name (getenv "HOME")))
         (home-len (length home)))
    (if (and
         (>= (length pwd) home-len)
         (equal home (substring pwd 0 home-len)))
        (concat "~" (substring pwd home-len))
      pwd)))



;; Make the directory name be shorter...by replacing all directory
;; names with just its first names. However, we leave the last two to
;; be the full names. Why yes, I did steal this.


(defun pwd-shorten-dirs (pwd)
  "Shorten all directory names in PWD except the last two."
  (let ((p-lst (split-string pwd "/")))
    (if (> (length p-lst) 2)
        (concat
         (mapconcat (lambda (elm) (if (zerop (length elm)) ""
                               (substring elm 0 1)))
                    (butlast p-lst 2)
                    "/")
         "/"
         (mapconcat (lambda (elm) elm)
                    (last p-lst 2)
                    "/"))
      pwd)))  ;; Otherwise, we just return the PWD



;; Break up the directory into a "parent" and a "base":


(defun split-directory-prompt (directory)
  (if (string-match-p ".*/.*" directory)
      (list (file-name-directory directory) (file-name-base directory))
    (list "" directory)))



;; Using virtual environments for certain languages is helpful to know,
;; especially since I change them based on the directory.


(defun ruby-prompt ()
  "Returns a string (may be empty) based on the current Ruby Virtual Environment."
  (let* ((executable "~/.rvm/bin/rvm-prompt")
         (command    (concat executable "v g")))
    (when (file-exists-p executable)
      (let* ((results (shell-command-to-string executable))
             (cleaned (string-trim results))
             (gem     (propertize "\xe92b" 'face `(:family "alltheicons"))))
        (when (and cleaned (not (equal cleaned "")))
          (s-replace "ruby-" gem cleaned))))))

(defun python-prompt ()
  "Returns a string (may be empty) based on the current Python
   Virtual Environment. Assuming the M-x command: `pyenv-mode-set'
   has been called."
  (when (fboundp #'pyenv-mode-version)
    (let ((venv (pyenv-mode-version)))
      (when venv
        (concat
         (propertize "\xe928" 'face `(:family "alltheicons"))
         (pyenv-mode-version))))))



;; Now tie it all together with a prompt function can color each of the
;; prompts components.


(defun eshell/eshell-local-prompt-function ()
  "A prompt for eshell that works locally (in that is assumes
that it could run certain commands) in order to make a prettier,
more-helpful local prompt."
  (interactive)
  (let* ((pwd        (eshell/pwd))
         (directory (split-directory-prompt
                     (pwd-shorten-dirs
                      (pwd-replace-home pwd))))
         (parent (car directory))
         (name   (cadr directory))
         (branch (curr-dir-git-branch-string pwd))
         (ruby   (when (not (file-remote-p pwd)) (ruby-prompt)))
         (python (when (not (file-remote-p pwd)) (python-prompt)))

         (dark-env (eq 'dark (frame-parameter nil 'background-mode)))
         (for-bars                 `(:weight bold))
         (for-parent  (if dark-env `(:foreground "dark orange") `(:foreground "blue")))
         (for-dir     (if dark-env `(:foreground "orange" :weight bold)
                        `(:foreground "blue" :weight bold)))
         (for-git                  `(:foreground "green"))
         (for-ruby                 `(:foreground "red"))
         (for-python               `(:foreground "#5555FF")))

    (concat
     (propertize "⟣─ "    'face for-bars)
     (propertize parent   'face for-parent)
     (propertize name     'face for-dir)
     (when branch
       (concat (propertize " ── "    'face for-bars)
               (propertize branch   'face for-git)))
     (when ruby
       (concat (propertize " ── " 'face for-bars)
               (propertize ruby   'face for-ruby)))
     (when python
       (concat (propertize " ── " 'face for-bars)
               (propertize python 'face for-python)))
     (propertize "\n"     'face for-bars)
     (propertize (if (= (user-uid) 0) " #" " $") 'face `(:weight ultra-bold))
     ;; (propertize " └→" 'face (if (= (user-uid) 0) `(:weight ultra-bold :foreground "red") `(:weight ultra-bold)))
     (propertize " "    'face `(:weight bold)))))

(setq-default eshell-prompt-function #'eshell/eshell-local-prompt-function)



;; Turn off the default prompt, otherwise, it won't use ours:


(setq eshell-highlight-prompt nil)



;; Let's try a version that doesn't put the current working directory
;; in the mode-line's buffer title:


(defun eshell-here ()
  "Opens up a new shell in the directory associated with the
    current buffer's file. The eshell is renamed to match that
    directory to make multiple eshell windows easier."
  (interactive)
  (let* ((height (/ (window-total-height) 3)))
    (split-window-vertically (- height))
    (other-window 1)
    (eshell "new")
    (insert (concat "ls"))
    (eshell-send-input)))

(bind-key "C-!" 'eshell-here)



;; Used to ~C-d~ exiting from a shell? Want it to keep working, but still
;; allow deleting a character? We can have it both (thanks to [[https://github.com/wasamasa/dotemacs/blob/master/init.org#eshell][wasamasa]]):


(use-package eshell
  :config
  (defun ha/eshell-quit-or-delete-char (arg)
    (interactive "p")
    (if (and (eolp) (looking-back eshell-prompt-regexp))
        (progn
          (eshell-life-is-too-much) ; Why not? (eshell/exit)
          (ignore-errors
            (delete-window)))
      (delete-forward-char arg)))
  :init
  (add-hook 'eshell-mode-hook
            (lambda ()
              (bind-keys :map eshell-mode-map
                         ("C-d" . ha/eshell-quit-or-delete-char)))))

;; Shell There
;;    :PROPERTIES:
;;    :CUSTOM_ID: remote-shell
;;    :END:

;;    Would be nice to be able to run an eshell session and use Tramp to
;;    connect to the remote host in one fell swoop:


(defun eshell-there (host)
  "Creates an eshell session that uses Tramp to automatically
connect to a remote system, HOST.  The hostname can be either the
IP address, or FQDN, and can specify the user account, as in
root@blah.com. HOST can also be a complete Tramp reference."
  (interactive "sHost: ")

  (let* ((default-directory
           (cond
            ((string-match-p "^/" host) host)

            ((string-match-p (ha/eshell-host-regexp 'full) host)
             (string-match (ha/eshell-host-regexp 'full) host) ;; Why!?
             (let* ((user1 (match-string 2 host))
                    (host1 (match-string 3 host))
                    (user2 (match-string 6 host))
                    (host2 (match-string 7 host)))
               (if host1
                   (ha/eshell-host->tramp user1 host1)
                 (ha/eshell-host->tramp user2 host2))))

            (t (format "/%s:" host)))))
    (eshell-here)))

;; Shell Here to There

;;    Since I have Org files that contains tables of system to remotely
;;    connect to, I figured I should have a little function that can jump
;;    to a host found listed anywhere on the line.

;;    The regular expression associated with IP addresses, hostnames, user
;;    accounts (of the form, =jenkins@my.build.server=, or even full Tramp
;;    references, is a bit...uhm, hairy.  And since I want to reuse these,
;;    I will hide them in a function:


(defun ha/eshell-host-regexp (regexp)
  "Returns a particular regular expression based on symbol, REGEXP"
  (let* ((user-regexp      "\\(\\([[:alpha:].]+\\)@\\)?")
         (tramp-regexp     "\\b/ssh:[:graph:]+")
         (ip-char          "[[:digit:]]")
         (ip-plus-period   (concat ip-char "+" "\\."))
         (ip-regexp        (concat "\\(\\(" ip-plus-period "\\)\\{3\\}" ip-char "+\\)"))
         (host-char        "[[:alpha:][:digit:]-]")
         (host-plus-period (concat host-char "+" "\\."))
         (host-regexp      (concat "\\(\\(" host-plus-period "\\)+" host-char "+\\)"))
         (horrific-regexp  (concat "\\b"
                                   user-regexp ip-regexp
                                   "\\|"
                                   user-regexp host-regexp
                                   "\\b")))
    (cond
     ((eq regexp 'tramp) tramp-regexp)
     ((eq regexp 'host)  host-regexp)
     ((eq regexp 'full)  horrific-regexp))))



;; The function to scan a line for hostname patterns uses different
;; function calls that what I could use for =eshell-there=, so let's
;; =save-excursion= and hunt around:


(defun ha/eshell-scan-for-hostnames ()
  "Helper function to scan the current line for any hostnames, IP
or Tramp references.  This returns a tuple of the username (if
found) and the hostname.

If a Tramp reference is found, the username part of the tuple
will be `nil'."
  (save-excursion
    (goto-char (line-beginning-position))
    (if (search-forward-regexp (ha/eshell-host-regexp 'tramp) (line-end-position) t)
        (cons nil (buffer-substring-no-properties (match-beginning 0) (match-end 0)))

      ;; Returns the text associated with match expression, NUM or `nil' if no match was found.
      (cl-flet ((ha/eshell-get-expression (num) (if-let ((first (match-beginning num))
                                                         (end   (match-end num)))
                                                    (buffer-substring-no-properties first end))))

        (search-forward-regexp (ha/eshell-host-regexp 'full) (line-end-position))

        ;; Until this is completely robust, let's keep this debugging code here:
        ;; (message (mapconcat (lambda (tup) (if-let ((s (car tup))
        ;;                                       (e (cadr tup)))
        ;;                                  (buffer-substring-no-properties s e)
        ;;                                "null"))
        ;;             (-partition 2 (match-data t)) " -- "))

        (let ((user1 (ha/eshell-get-expression 2))
              (host1 (ha/eshell-get-expression 3))
              (user2 (ha/eshell-get-expression 6))
              (host2 (ha/eshell-get-expression 7)))
          (if host1
              (cons user1 host1)
            (cons user2 host2)))))))



;; Tramp reference can be long when attempting to connect as another
;; user account using the pipe symbol.


(defun ha/eshell-host->tramp (username hostname &optional prefer-root)
  "Returns a TRAMP reference based on a USERNAME and HOSTNAME
that refers to any host or IP address."
  (cond ((string-match-p "^/" host)
           host)
        ((or (and prefer-root (not username)) (equal username "root"))
           (format "/ssh:%s|sudo:%s:" hostname hostname))
        ((or (null username) (equal username user-login-name))
           (format "/ssh:%s:" hostname))
        (t
           (format "/ssh:%s|sudo:%s|sudo@%s:%s:" hostname hostname username hostname))))



;; Finally

(defun eshell-here-on-line (p)
  "Search the current line for an IP address or hostname, and call the `eshell-here' function.

Call with PREFIX to connect with the `root' useraccount, via
`sudo'."
  (interactive "p")
  (destructuring-bind (user host) (ha/eshell-scan-for-hostnames)
    (let ((default-directory (ha/eshell-host->tramp user host (> p 1))))
      (message "Connecting to: %s" default-directory)
      ;; With the `default-directory' set to a Tramp reference, rock on!
      (eshell-here))))

(bind-key "M-s-1" #'eshell-here-on-line)

;; Shell Favorites

;;     Since the Tramp syntax is a bit verbose, a few /wrapper functions/
;;     would make things easier. Also, having a list of /favorite hosts/
;;     with simpler names would also be a nice feature.

;;     Since Emacs doesn't have a memoize function, define a global
;;     variable, =remote-shell-fav-hosts=, a hash that maps nicknames of
;;     hosts to their IP address.


(defvar remote-shell-fav-hosts (make-hash-table :test 'equal)
  "Table of host aliases for IPs or other actual references.")



;; Can we make a list of what hosts are /pre-known/? What if no hosts
;; have been defined? In this case, we want to call the function,
;; =remote-shell-fav-hosts-get= to populate it:



;;add the host manually for testing
(puthash "papkaleb-tyrell.aka.corp.amazon.com" "papkaleb-tyrell.aka.corp.amazon.com" remote-shell-fav-hosts)

(defun remote-shell-fav-hosts-map ()
;;populate the function with the results from the hash table
remote-shell-fav-hosts)



;; In order to populate the =completing-read=, we need a list of hosts:


(defun remote-shell-fav-hosts-list ()
  "Simply returns a list of known hosts from the cached map, or
populates it first if it is empty and the
`remote-shell-fav-hosts-get' function has been defined."
(require 'subr-x)
(hash-table-keys (remote-shell-fav-hosts-map)))



;; Most remote access is done with Tramp, so this function simplifies
;; the complex Tramp string creation, mostly using an =sudo= pipe for
;; =root= access. If the =remote-shell-fav-hosts= hash is empty, we'll
;; populate it when this is called.


(defun remote-shell-tramp-connection (hostname &optional root directory)
  "Return a TRAMP connection string to HOSTNAME. If ROOT is
non-nil, returns an sudo compatible string."
  (when (null directory)
    (setq directory ""))

  ;; The ip address is either the value from a key in our cache, or whatever we pass in:
  (let ((ipaddr (gethash hostname (remote-shell-fav-hosts-map) hostname)))
    (if root
        (format "/ssh:%s|sudo:%s:%s" ipaddr ipaddr directory)
        (format "/ssh:%s:%s"         ipaddr directory))))



;; If the window containing the results of the shell connection or
;; shell command is the same, we can take advantage of that from
;; multiple functions, so:


(defun remote-shell-buffer-name (hostname &optional command-str default-name)
  "Returns a standard format for our remote shell command buffer
windows based on the HOSTNAME and the COMMAND-STR. Uses
DEFAULT-NAME if specified."
  (cond
   (default-name     default-name)
   (command-str      (let ((command (car (split-string command-str))))
                        (format "*%s:%s*" hostname command)))
   (t                (format "*%s*" hostname))))



;; Our simple wrapper function for accessing a remote shell, should
;; use =ido= if available.


(defun remote-shell (hostname &optional root)
  "Start an shell experience on HOSTNAME, that can be an alias to
a virtual machine from my 'cloud' server. With prefix command, opens
the shell as the root user account."
  (interactive
   (list (if (fboundp #'ido-completing-read)
             (ido-completing-read "Hostname: " (remote-shell-fav-hosts-list))
           (completing-read "Hostname: " (remote-shell-fav-hosts-list)))))
  (when (equal current-prefix-arg '(4))
    (setq root t))
  (let ((default-directory (remote-shell-tramp-connection hostname root)))
    (shell (remote-shell-buffer-name hostname))))



;; With the way Emacs Lisp's =interactive= behaves, I'm not sure how to
;; DRY this function to be a simple alias with the exception of
;; using eshell:


(defun eshell-favorite (hostname &optional root)
  "Start an shell experience on HOSTNAME, that can be an alias to
a virtual machine from my 'cloud' server. With prefix command, opens
the shell as the root user account."
  (interactive
   (list (if (fboundp #'ido-completing-read)
             (ido-completing-read "Hostname: " (remote-shell-fav-hosts-list))
           (completing-read "Hostname: " (remote-shell-fav-hosts-list)))))
  (when (equal current-prefix-arg '(4))
    (setq root t))
  (let ((default-directory (remote-shell-tramp-connection hostname root)))
    (eshell (remote-shell-buffer-name hostname))))



;; Instead of starting a shell, what if we just ran a command using the
;; =shell-command= (so that commands that end in a =&= are automatically
;; ran asynchronously.


(defun remote-shell-command (hostname command
                                      &optional root bufname directory)
  "On HOSTNAME, run COMMAND (if the command ends with &, run
asynchronously). With a `C-u' prefix, run the command as ROOT.
When non-interactive, you can specify BUFNAME for the buffer's
name, and DIRECTORY where the command should run."
  (interactive
   (list (if #'ido-completing-read
             (ido-completing-read "Hostname: " (remote-shell-fav-hosts-list))
           (completing-read "Hostname: " (remote-shell-fav-hosts-list)))
         (read-string "Command: ")))
  (when (equal current-prefix-arg '(4))
    (setq root t))
  (let ((default-directory (remote-shell-tramp-connection hostname root directory)))
    (shell-command command (remote-shell-buffer-name hostname command bufname))))



;; With the above helper functions, we can loop over a list of machines,
;; and kick off remote work on each one:


(defun remote-shell-commands (clients command
                                      &optional root async directory)
  "On each host entry in CLIENTS, run the shell COMMAND,
optionally as ROOT. If ASYNC is non-nil, appends the `&' to the
shell command in order to run it asynchronously. Runs the command
in the default home directory unless DIRECTORY is specified."
  (if async
      (setq command (concat command " &")))
  (dolist (host clients)
    (remote-shell-command host command root nil directory)))



;; The results of each command is stored in a separate buffer, and
;; since we know what the names are, this command will attempt to load
;; them on the side... yeah, this is a bit ugly.


(defun remote-shell-commands-show (clients command)
  "Shows each buffer of a previously executed command. For example:

        (let ((my-favs '(\"os-controller\" \"contrail-controller\"
                         \"compute\" \"nagios\" \"elk\"))
              (command \"chef-client\"))
          (remote-shell-commands my-favs command t t)
          (remote-shell-commands-show my-favs command))"

  (delete-other-windows)
  (let ((first-time t))
    (dolist (host clients)
      (if (not first-time)
          (split-window-vertically)
        (split-window-horizontally)
        (setq first-time nil))

      (other-window 1)
      (switch-to-buffer (remote-shell-buffer-name host command))
      (balance-windows)
      (sit-for 0.5))))

;; Tramp

;;   The ability to edit files on remote systems is a wonderful win,
;;   since it means I don't need to have my Emacs environment running on
;;   remote machines (still a possibility, just not a requirement).

;;   According to [[http://www.gnu.org/software/emacs/manual/html_node/tramp/Filename-Syntax.html][the manual]], I can access a file over SSH, via:

;;   #+BEGIN_EXAMPLE
;;   /ssh:10.52.224.67:blah
;;   #+END_EXAMPLE

;;   However, if I set the default method to SSH, I can do this:

;;   #+BEGIN_EXAMPLE
;;   /10.52.224.67:blah
;;   #+END_EXAMPLE

;;   So, let's do it...


(setq tramp-default-method "ssh")

;; Better Command Line History

;;   On [[http://www.reddit.com/r/emacs/comments/1zkj2d/advanced_usage_of_eshell/][this discussion]] a little gem for using IDO to search back through
;;   the history, instead of =M-R= to display the history in a selectable
;;   buffer.

;;   Also, while =M-p= cycles through the history, =M-P= actually moves
;;   up the history in the buffer (easier than =C-c p= and =C-c n=?):

;;   Since eshell's history often gets confused with blank lines in the
;;   output, we can fix that with a better replacement functions pegged
;;   to the =eshell-prompt-regexp= string:


(defun eshell-next-prompt (n)
  "Move to end of Nth next prompt in the buffer. See `eshell-prompt-regexp'."
  (interactive "p")
  (re-search-forward eshell-prompt-regexp nil t n)
  (when eshell-highlight-prompt
    (while (not (get-text-property (line-beginning-position) 'read-only) )
      (re-search-forward eshell-prompt-regexp nil t n)))
  (eshell-skip-prompt))

(defun eshell-previous-prompt (n)
  "Move to end of Nth previous prompt in the buffer. See `eshell-prompt-regexp'."
  (interactive "p")
  (backward-char)
  (eshell-next-prompt (- n)))

(defun eshell-insert-history ()
  "Displays the eshell history to select and insert back into your eshell."
  (interactive)
  (insert (ido-completing-read "Eshell history: "
                               (delete-dups
                                (ring-elements eshell-history-ring)))))

(add-hook 'eshell-mode-hook (lambda ()
    (define-key eshell-mode-map (kbd "M-S-P") 'eshell-previous-prompt)
    (define-key eshell-mode-map (kbd "M-S-N") 'eshell-next-prompt)
    (define-key eshell-mode-map (kbd "M-r") 'eshell-insert-history)))

;; Helpers

;;   Sometimes you just need to change something about the current file
;;   you are editing...like the permissions or even execute it. Hitting
;;   =Command-1= will prompt for a shell command string and then append
;;   the current file to it and execute it.


(defun execute-command-on-file-buffer (cmd)
  (interactive "sCommand to execute: ")
  (let* ((file-name (buffer-file-name))
         (full-cmd (concat cmd " " file-name)))
    (shell-command full-cmd)))

(bind-key "A-1" #'execute-command-on-file-buffer)

(defun execute-command-on-file-directory (cmd)
  (interactive "sCommand to execute: ")
  (let* ((dir-name (file-name-directory (buffer-file-name)))
         (full-cmd (concat "cd " dir-name "; " cmd)))
    (shell-command full-cmd)))

(bind-key "A-!" #'execute-command-on-file-directory)
(bind-key "s-!" #'execute-command-on-file-directory)



;; Some prompts, shells and terminal programs that display the exit
;; code as an icon in the fringe. So can the [[http://projects.ryuslash.org/eshell-fringe-status/][eshell-fringe-status]]
;; project. Seems to me, that if would be useful to rejuggle those
;; fringe markers so that the marker matched the command entered
;; (instead of seeing a red mark, and needing to scroll back in order
;; to wonder what command it was that made it). Still...


;;  (use-package eshell-fringe-status
;;    :config
 ;;   (add-hook 'eshell-mode-hook 'eshell-fringe-status-mode))

;; Technical Artifacts

;;   Make sure that we can simply =require= this library.


(provide 'init-eshell)
