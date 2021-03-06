; -*- mode: lisp; package: power-usage; encoding: shift-jis -*-

;;; power-usage/api.l
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
  (require "power-usage/api/tepco-usage-api")
  (require "power-usage/api/yahoo-setsuden-api")
  )

(in-package :power-usage)

(export '(*power-usage-area*

          get-latest-power-usage
          get-power-usage-at
          list-latest-power-usage
          list-power-usage-at

          ;; struct
          power-p
          power-area
          power-datetime
          power-capacity
          power-usage
          power-usage-rate
          ))

(defvar *power-usage-area* :tokyo
  "対象地域を指定。デフォルトは :tokyo。

:tokyo（東京電力管轄内）
:tohoku（東北電力管轄内）
:kansai（関西電力管轄内）
:chubu（中部電力管轄内）
:kyushu（九州電力管轄内）
")


(defun get-latest-power-usage (&key callback (area *power-usage-area*))
  "最新の電力使用状況を返します。"
  (get-power-usage callback area :latest t))

(defun get-power-usage-at (year month day hour &key callback (area *power-usage-area*))
  "指定された日時の電力使用状況を返します。"
  (get-power-usage callback area :datetime (list year month day hour)))


(defun list-latest-power-usage (&key callback (area *power-usage-area*))
  "今月の毎時の電力使用状況を、リストとして返します。"
  (multiple-value-bind (_ _ _ _ month year _)
      (decode-universal-time (get-universal-time))
    (get-power-usage callback area :datetime (list year month nil nil) :history t)))

(defun list-power-usage-at (year month day &key callback (area *power-usage-area*))
  "指定された月または日の毎時の電力使用状況を、リストとして返します。"
  (get-power-usage callback area :datetime (list year month day nil) :history t))


(defun get-power-usage (callback area &key datetime latest history)
  (flet ((parse (res)
           (parse-response area res :datetime datetime :latest latest :history history)))
    (let ((endpoint (build-api-endpoint area :datetime datetime :latest latest :history history)))
      (if callback
          (xhr:xhr-get-async endpoint :nomsg t :since :epoch
                             :onsuccess #'(lambda (res)
                                            (funcall callback (parse res))))
        (parse (xhr:xhr-get endpoint :nomsg t :since :epoch))))))


(provide "power-usage/api")

;;; End
