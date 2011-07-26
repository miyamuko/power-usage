; -*- mode: lisp; package: power-usage.tepco-usage-api; encoding: shift-jis -*-

;;; power-usage/api/tepco-usage-api.l
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
  (require "power-usage/api/base")

  (unless (find-package :power-usage.tepco-usage-api)
    (defpackage :power-usage.tepco-usage-api
      (:use
       :lisp
       :power-usage
       :power-usage.base
       ))
    ))

(in-package :power-usage.tepco-usage-api)

(export '(*api-endpoint*
          ))

(defvar *api-endpoint* "http://tepco-usage-api.appspot.com"
  "東京電力電力供給状況 API の URL")

(defvar *api-datetime-path* "~4,'0D/~2,'0D~@[/~2,'0D~]~@[/~2,'0D~].json"
  "指定した日付の電力使用状況を返す API のパス")

(defun parse-response-history (area res)
  (mapcar #'(lambda (json)
              (json->struct-impl area json))
          (response-json res)))

(defun json->struct-impl (area json)
  (make-power :area area
              :datetime (encode-universal-time
                         0 0 ($ json :hour)
                         ($ json :day) ($ json :month) ($ json :year))
              :capacity ($ json :capacity)
              :usage ($ json :usage)
              ))

(defun build-api-endpoint-history (area datetime)
  (let ((path (apply 'format nil *api-datetime-path* datetime)))
    (format nil "~A/~A" *api-endpoint* path)))

(add-extension '(:tokyo . "東京電力") :power-usage.tepco-usage-api)


(provide "power-usage/api/tepco-usage-api")

;;; End
