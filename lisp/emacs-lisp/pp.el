;;; pp.el --- pretty printer for Emacs Lisp  -*- lexical-binding: t -*-

;; Copyright (C) 1989, 1993, 2001-2023 Free Software Foundation, Inc.

;; Author: Randal Schwartz <merlyn@stonehenge.com>
;; Keywords: lisp

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

;;; Code:

(defvar font-lock-verbose)

(defgroup pp nil
  "Pretty printer for Emacs Lisp."
  :prefix "pp-"
  :group 'lisp)

(defcustom pp-escape-newlines t
  "Value of `print-escape-newlines' used by pp-* functions."
  :type 'boolean
  :group 'pp)

;;;###autoload
(defun pp-to-string (object)
  "Return a string containing the pretty-printed representation of OBJECT.
OBJECT can be any Lisp object.  Quoting characters are used as needed
to make output that `read' can handle, whenever this is possible."
  (with-temp-buffer
    (lisp-mode-variables nil)
    (set-syntax-table emacs-lisp-mode-syntax-table)
    (let ((print-escape-newlines pp-escape-newlines)
          (print-quoted t))
      (prin1 object (current-buffer)))
    (pp-buffer)
    (buffer-string)))

;;;###autoload
(defun pp-buffer ()
  "Prettify the current buffer with printed representation of a Lisp object."
  (interactive)
  (goto-char (point-min))
  (while (not (eobp))
    ;; (message "%06d" (- (point-max) (point)))
    (cond
     ((ignore-errors (down-list 1) t)
      (save-excursion
        (backward-char 1)
        (skip-chars-backward "'`#^")
        (when (and (not (bobp)) (memq (char-before) '(?\s ?\t ?\n)))
          (delete-region
           (point)
           (progn (skip-chars-backward " \t\n") (point)))
          (insert "\n"))))
     ((ignore-errors (up-list 1) t)
      (skip-syntax-forward ")")
      (delete-region
       (point)
       (progn (skip-chars-forward " \t\n") (point)))
      (insert ?\n))
     (t (goto-char (point-max)))))
  (goto-char (point-min))
  (indent-sexp))

;;;###autoload
(defun pp (object &optional stream)
  "Output the pretty-printed representation of OBJECT, any Lisp object.
Quoting characters are printed as needed to make output that `read'
can handle, whenever this is possible.
Output stream is STREAM, or value of `standard-output' (which see)."
  (princ (pp-to-string object) (or stream standard-output)))

(defun pp-display-expression (expression out-buffer-name)
  "Prettify and display EXPRESSION in an appropriate way, depending on length.
If a temporary buffer is needed for representation, it will be named
after OUT-BUFFER-NAME."
  (let* ((old-show-function temp-buffer-show-function)
	 ;; Use this function to display the buffer.
	 ;; This function either decides not to display it at all
	 ;; or displays it in the usual way.
	 (temp-buffer-show-function
          (lambda (buf)
            (with-current-buffer buf
              (goto-char (point-min))
              (end-of-line 1)
              (if (or (< (1+ (point)) (point-max))
                      (>= (- (point) (point-min)) (frame-width)))
                  (let ((temp-buffer-show-function old-show-function)
                        (old-selected (selected-window))
                        (window (display-buffer buf)))
                    (goto-char (point-min)) ; expected by some hooks ...
                    (make-frame-visible (window-frame window))
                    (unwind-protect
                        (progn
                          (select-window window)
                          (run-hooks 'temp-buffer-show-hook))
                      (when (window-live-p old-selected)
                        (select-window old-selected))
                      (message "See buffer %s." out-buffer-name)))
                (message "%s" (buffer-substring (point-min) (point))))))))
    (with-output-to-temp-buffer out-buffer-name
      (pp expression)
      (with-current-buffer standard-output
	(emacs-lisp-mode)
	(setq buffer-read-only nil)
        (setq-local font-lock-verbose nil)))))

;;;###autoload
(defun pp-eval-expression (expression)
  "Evaluate EXPRESSION and pretty-print its value.
Also add the value to the front of the list in the variable `values'."
  (interactive
   (list (read--expression "Eval: ")))
  (message "Evaluating...")
  (let ((result (eval expression lexical-binding)))
    (values--store-value result)
    (pp-display-expression result "*Pp Eval Output*")))

;;;###autoload
(defun pp-macroexpand-expression (expression)
  "Macroexpand EXPRESSION and pretty-print its value."
  (interactive
   (list (read--expression "Macroexpand: ")))
  (pp-display-expression (macroexpand-1 expression) "*Pp Macroexpand Output*"))

(defun pp-last-sexp ()
  "Read sexp before point.  Ignore leading comment characters."
  (with-syntax-table emacs-lisp-mode-syntax-table
    (let ((pt (point)))
      (save-excursion
        (forward-sexp -1)
        (read
         ;; If first line is commented, ignore all leading comments:
         (if (save-excursion (beginning-of-line) (looking-at-p "[ \t]*;"))
             (let ((exp (buffer-substring (point) pt))
                   (start nil))
               (while (string-match "\n[ \t]*;+" exp start)
                 (setq start (1+ (match-beginning 0))
                       exp (concat (substring exp 0 start)
                                   (substring exp (match-end 0)))))
               exp)
           (current-buffer)))))))

;;;###autoload
(defun pp-eval-last-sexp (arg)
  "Run `pp-eval-expression' on sexp before point.
With ARG, pretty-print output into current buffer.
Ignores leading comment characters."
  (interactive "P")
  (if arg
      (insert (pp-to-string (eval (elisp--eval-defun-1
                                   (macroexpand (pp-last-sexp)))
                                  lexical-binding)))
    (pp-eval-expression (elisp--eval-defun-1
                         (macroexpand (pp-last-sexp))))))

;;;###autoload
(defun pp-macroexpand-last-sexp (arg)
  "Run `pp-macroexpand-expression' on sexp before point.
With ARG, pretty-print output into current buffer.
Ignores leading comment characters."
  (interactive "P")
  (if arg
      (insert (pp-to-string (macroexpand-1 (pp-last-sexp))))
    (pp-macroexpand-expression (pp-last-sexp))))

(provide 'pp)				; so (require 'pp) works

;;; pp.el ends here
