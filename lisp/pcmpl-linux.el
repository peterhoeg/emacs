;;; pcmpl-linux.el --- functions for dealing with GNU/Linux completions  -*- lexical-binding: t -*-

;; Copyright (C) 1999-2023 Free Software Foundation, Inc.

;; Package: pcomplete

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; These functions are for use with GNU/Linux.  Since they depend on a
;; certain knowledge of the layout of such systems, they probably
;; won't work very well on other operating systems.

;;; Code:

(provide 'pcmpl-linux)

(require 'pcomplete)

;; Functions:

;;;###autoload
(defun pcomplete/kill ()
  "Completion for GNU/Linux `kill', using /proc filesystem."
  (if (pcomplete-match "^-\\(.*\\)" 0)
      (pcomplete-here
       (pcomplete-uniquify-list
	(split-string
	 (pcomplete-process-result "kill" "-l")))
       (pcomplete-match-string 1 0)))
  (while (pcomplete-here
	  (if (file-directory-p "/proc")
              (directory-files "/proc" nil "\\`[0-9]+\\'"))
	  nil #'identity)))

;;;###autoload
(defun pcomplete/umount ()
  "Completion for GNU/Linux `umount'."
  (pcomplete-opt "hVafrnvt(pcmpl-linux-fs-types)")
  (while (pcomplete-here (pcmpl-linux-mounted-directories)
			 nil #'identity)))

;;;###autoload
(defun pcomplete/mount ()
  "Completion for GNU/Linux `mount'."
  (pcomplete-opt "hVanfFrsvwt(pcmpl-linux-fs-types)o?L?U?")
  (while (pcomplete-here (pcomplete-entries) nil #'identity)))

(defconst pcmpl-linux-fs-modules-path-format "/lib/modules/%s/kernel/fs/")

(defun pcmpl-linux-fs-types ()
  "Return a list of available fs modules on GNU/Linux systems."
  (let ((kernel-ver (pcomplete-process-result "uname" "-r")))
    (directory-files
     (format pcmpl-linux-fs-modules-path-format kernel-ver))))

(defconst pcmpl-linux-mtab-file "/etc/mtab")

(defun pcmpl-linux-mounted-directories ()
  "Return a list of mounted directory names."
  (let (points)
    (when (file-readable-p pcmpl-linux-mtab-file)
      (with-temp-buffer
        (insert-file-contents-literally pcmpl-linux-mtab-file)
	(while (not (eobp))
	  (let* ((line (buffer-substring (point) (line-end-position)))
		 (args (split-string line " ")))
	    (setq points (cons (nth 1 args) points)))
	  (forward-line)))
      (pcomplete-uniquify-list points))))

(defun pcomplete-pare-list (l r)
  "Destructively remove from list L all elements matching any in list R.
Test is done using `equal'."
  (while (and l (and r (member (car l) r)))
    (setq l (cdr l)))
  (let ((m l))
    (while m
      (while (and (cdr m)
		  (and r (member (cadr m) r)))
	(setcdr m (cddr m)))
      (setq m (cdr m))))
  l)

(defun pcmpl-linux-mountable-directories ()
  "Return a list of mountable directory names."
  (let (points)
    (when (file-readable-p "/etc/fstab")
      (with-temp-buffer
	(insert-file-contents-literally "/etc/fstab")
	(while (not (eobp))
	  (let* ((line (buffer-substring (point) (line-end-position)))
		 (args (split-string line "\\s-+")))
	    (setq points (cons (nth 1 args) points)))
	  (forward-line)))
      (pcomplete-pare-list
       (pcomplete-uniquify-list points)
       (cons "swap" (pcmpl-linux-mounted-directories))))))

;;; pcmpl-linux.el ends here
