; -*- mode: lisp; package: power-usage; encoding: shift_jis -*-

;;; power-usage/macros.l
;;
;; Copyright (c) 2011 MIYAMUKO Katsuyuki.
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Code:

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "power-usage/package")
  )

(in-package :power-usage)

(defmacro with-selected-buffer (buffer &body body)
  `(with-set-buffer
     (let ((#1=#:new ,buffer)
           (#2=#:old (selected-buffer)))
       (unwind-protect
           (if (get-buffer-window #1#)
               (with-selected-window
                 (set-window (get-buffer-window #1#))
                 ,@body)
             (progn
               (set-buffer #1#)
               ,@body))
         (set-buffer #2#)))))
(setf (get 'with-selected-buffer 'lisp-indent-hook) 0)

(defmacro with-write-buffer (&body body)
  `(let ((#1=#:read-only buffer-read-only))
     (unwind-protect
         (progn
           (setf buffer-read-only nil)
           ,@body)
       (setf buffer-read-only #1#))))
(setf (get 'with-write-buffer 'lisp-indent-hook) 0)

(defmacro with-graph-buffer (&body body)
  `(let ((#1=#:buffer (find-graph-buffer)))
     (when #1#
       (with-selected-buffer #1#
         (with-write-buffer
           ,@body)))))
(setf (get 'with-graph-buffer 'lisp-indent-hook) 0)

(defmacro with-output-to-graph-buffer (&body body)
  `(with-selected-window
     (with-output-to-temp-buffer (*power-usage-graph-buffer-name*
                                  *power-usage-graph-buffer-height*)
       ,@body)))
(setf (get 'with-output-to-graph-buffer 'lisp-indent-hook) 0)


(provide "power-usage/macros")

;;; End
