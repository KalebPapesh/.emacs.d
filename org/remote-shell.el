(setq hostfile "~/.emacs.d/hosts.txt")

(defun add-host ()
       (interactive)
       (setq connection-name (read-string "Name: "))
       (setq connection-user (read-string "User: "))
       (setq connection-host (read-string "Hostname: "))
       (setq connection-string (concat connection-name " " connection-user " " connection-host))
       (shell-command (format "echo '%s' >> %s" connection-string hostfile)))

(defun get-hosts (filePath)
	 "get a list of hosts for later"
	 (with-temp-buffer
	   (insert-file-contents filePath)
	   (setq hosts (split-string (buffer-string) "\n" t))))

(defun list-connection-names (list-host)
    "Get a list of host connection names for an ido list"
	 (setq connection-names '())
	 (let ((x 0))
	   (while (/= x (length list-host))
	     (push (nth 0 (split-string (nth x list-host) " " t)) connection-names)
	   (setq x (+ x 1)))))

(defun load-hosts ()
    "Check to see if very important vars are loaded
    and if not, load them"
    (if (boundp 'hosts) nil
        (get-hosts hostfile))

    (if (boundp 'connection-names) nil
        (list-connection-names hosts)))

(defun find-host-in-list (name host-list)
	 "find a host given the name of the connection in the host list
	 and load the connection vars for later"
	 (let ((x 0))
	 (while (/= x (length host-list))
	   (if (member name (split-string (nth x host-list) " " t))
	       (setq found-host (member name (split-string (nth x hosts) " " t)))
	     (setq connection-name (nth 0 found-host))
	     (setq connection-user (nth 1 found-host))
	     (setq connection-host (nth 2 found-host)))
	   (setq x (+ x 1)))))

(defun create-shell (connection-user connection-host)
    "Create the shell"
    (load-hosts)
    (interactive)
    (setq shell-name (generate-new-buffer-name (format "*rshell-%s*" connection-host)))
    (let ((default-directory (format "/ssh:%s@%s:~/" connection-user connection-host)))
    (shell shell-name)))

(defun remote-shell (&optional name)
    "prompt user to pick a host to remote into"
    (load-hosts)
    (interactive)
    (if name
       (setq choice name)
      (setq choice (message "%s" (ido-completing-read "SSH into: " connection-names))))
    (find-host-in-list choice hosts)
    (create-shell connection-user connection-host)
    (delete-other-windows))

(defun remote-shell-command (&optional name command)
   "On NAME run COMMAND. (if the command ends with &, run asyncronously)"
   (load-hosts)
   (interactive)
   (if (and name command)
       (progn
	 (setq choice-name name)
	 (find-host-in-list choice-name hosts)
	 (setq choice-command (format "%s" command)))
     (progn
       (setq choice-name (message "%s" (ido-completing-read "Run command on: " connection-names)))
       (setq choice-command (read-string "Command: "))
       (find-host-in-list choice-name hosts)))

(setq shell-buffer-check
   (elt (seq-filter
       (lambda (buf)
 	   (string-prefix-p (format "*rshell-%s*" connection-host) (buffer-name buf)))
 		  (buffer-list)) 0))

  (if (get-buffer shell-buffer-check )
      (progn
       (message "found shell")
       (let ((default-directory (format "/ssh:%s@%s:~/" connection-user connection-host)))
 	 (shell-command choice-command shell-buffer-check)))
    (progn
      (message "create shell")
      (setq shell-name (generate-new-buffer-name (format "*rshell-%s*" connection-host)))
      (let ((default-directory (format "/ssh:%s@%s:~/" connection-user connection-host)))
       (shell-command choice-command shell-name)))))

(defun kill-shells ()
  (interactive)
  (kill-matching-buffers "^\*rshell-.*$")
  (kill-matching-buffers "^\*shell.*$"))
