;;; autocommit.el --- A mode for autocommitting changes in a particular folder -*- lexical-binding: t -*-

;; Copyright (C) 2017 Alexey Kutepov <reximkut@gmail.com>

;; Author: Alexey Kutepov <reximkut@gmail.com>
;; URL: https://github.com/rexim/autocommit-el

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; A mode for autocommitting changes in a particular folder

;;; Code:

(require 'autocommit--instances)

;;; TODO(c3bdae31-4329-4217-98a0-743b9dcbb6d2): extract autocommit into a separate package
;;;
;;; Once e266bfaa-2a01-4881-9e7f-ce2c592f7cdd is done, I think we can do that.

;;; TODO(e266bfaa-2a01-4881-9e7f-ce2c592f7cdd): support several autocommit folders simultaneously
;;; Subtasks:
;;; - 7d371cfc-06e3-42a3-91cf-a9d435e9941f
(defvar autocommit--offline nil)
(defvar autocommit--pull-lock nil)
(defvar autocommit--lock nil)
(defvar autocommit--changed nil)

(defun autocommit--create-dir-locals (file-name)
  (write-region "((nil . ((eval . (autocommit-dir-locals)))))"
                nil file-name))

(defun autocommit--y-or-n-if (predicate question action)
  (when (or (not (funcall predicate))
            (y-or-n-p question))
    (funcall action)))

;;; TODO(4229cf9a-4768-4f5e-aca1-865256c64a23): autocommit-init-dir should modify dir locals file on AST level
;;;
;;; Right know it just overrides .dir-locals file on text level. I
;;; want it to
;;; - read .dir-locals,
;;; - parse the assoc list,
;;; - check if there is already autocommit stuff
;;; - add autocommit stuff to the assoc list if needed
;;; - and write it back to the file
;;;
;;; That will enable us with modifying dir locals that contains custom
;;; stuff unrelated to autocommit
(defun autocommit-init-dir (&optional dir)
  "Initialize autocommit folder."
  (interactive "DAutocommit directory: ")
  (let* ((autocommit-dir (if dir dir default-directory))
         (file-name (concat autocommit-dir
                            dir-locals-file)))
    (autocommit--y-or-n-if (-partial #'file-exists-p file-name)
                           (format "%s already exists. Replace it?" file-name)
                           (-partial #'autocommit--create-dir-locals file-name))))

(defun autocommit-dir-locals ()
  "The function that has to be put into the .dir-locals.el file
of the autocommit folder as evaluated for any mode."
  (interactive)
  (auto-revert-mode 1)
  (autocommit--autopull-changes)
  (add-hook 'after-save-hook
            'autocommit--autocommit-changes
            nil 'make-it-local))

(defun autocommit-toggle-offline ()
  "Toggle between OFFLINE and ONLINE modes.

Autocommit can be in two modes: OFFLINE and ONLINE. When ONLINE
autocommit--autocommit-changes does `git commit && git push'. When OFFLINE
autocommit does only `git commit'."
  (interactive)
  (setq autocommit--offline (not autocommit--offline))
  (if autocommit--offline
      (message "[OFFLINE] Autocommit Mode")
    (message "[ONLINE] Autocommit Mode")))

(defun autocommit-reset-locks ()
  "Reset all of the autocommit locks.

Autocommit is asynchronous and to perform its job without any
race conditions it maintains a set of internal locks. If this set
goes into an incosistent state you can reset them with this
function."
  (interactive)
  (setq autocommit--lock nil)
  (setq autocommit--changed nil))

(defun autocommit--autopull-changes ()
  "Pull the recent changes.

Should be invoked once before working with the content under
autocommit. Usually put into the dir locals file."
  (interactive)
  (when (not autocommit--pull-lock)
    (setq autocommit--pull-lock t)
    (if autocommit--offline
        (message "[OFFLINE] NOT Syncing the Agenda")
      (if (y-or-n-p "Sync the Agenda?")
          (progn
            (message "Syncing the Agenda")
            (shell-command "git pull"))
        (progn
          (setq autocommit--offline t)
          (message "[OFFLINE] NOT Syncing the Agenda"))))))

(defun autocommit--autocommit-changes ()
  "Commit all of the changes under the autocommit folder.

Should be invoked each time a change is made. Usually put into
dir locals file."
  (interactive)
  (if autocommit--lock
      (setq autocommit--changed t)
    (setq autocommit--lock t)
    (setq autocommit--changed nil)
    (set-process-sentinel (autocommit--run-commit-process)
                          'autocommit--beat)))

(defun autocommit--run-commit-process ()
  (let ((autocommit-message (format-time-string "Autocommit %s")))
    (let ((default-directory "~/Documents/Agenda/"))
      (start-process-shell-command
       "Autocommit"
       "*Autocommit*"
       (format (if autocommit--offline
                   "git add -A && git commit -m \"%s\""
                 "git add -A && git commit -m \"%s\" && git push origin master")
               autocommit-message)))))

(defun autocommit--beat (process event)
  (message (if autocommit--offline
               "[OFFLINE] Autocommit: %s"
             "Autocommit: %s")
           event)
  (if (not autocommit--changed)
      (setq autocommit--lock nil)
    (setq autocommit--changed nil)
    (set-process-sentinel (autocommit--run-commit-process)
                          'autocommit--beat)))

(provide 'autocommit)

;;; autocommit.el ends here
