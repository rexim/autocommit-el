;;; autocommit--instances.el --- Autocommit instances -*- lexical-binding: t -*-

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

;; Autocommit instances

;;; Code:

(defvar autocommit---global-path-to-instance-map (make-hash-table :test #'equal))

(defun autocommit---new-instance ()
  '((offline . nil)
    (pulled . nil)
    (committing . nil)
    (changed . nil)))

(defun autocommit---get-instance (instance-id)
  (gethash instance-id autocommit---global-path-to-instance-map))

(defun autocommit---replace-instance (instance-id instance)
  (puthash instance-id instance autocommit---global-path-to-instance-map))

(defun autocommit---create-instance (instance-id)
  (let ((instance (autocommit---new-instance)))
    (autocommit---replace-instance instance-id instance)))

(defun autocommit---get-or-create-instance (instance-id)
  (let ((instance (autocommit---get-instance instance-id)))
    (if instance instance
      (autocommit---create-instance instance-id))))

(defun autocommit--swap-instance (folder-path mapper)
  (let* ((instance-id (file-truename folder-path))
         (instance (autocommit---get-or-create-instance instance-id)))
    (autocommit---replace-instance instance-id (funcall mapper instance))))

(provide 'autocommit--instances)

;;; autocommit--instances.el ends here
