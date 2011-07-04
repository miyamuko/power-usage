; -*- mode: lisp; package: power-usage.yahoo-setsuden-api; encoding: shift-jis -*-

;;; power-usage/api/yahoo-setsuden-api.l
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

  (unless (find-package :power-usage.yahoo-setsuden-api)
    (defpackage :power-usage.yahoo-setsuden-api
      (:use
       :lisp
       :editor
       :power-usage
       :power-usage.base
       ))
    ))

(in-package :power-usage.yahoo-setsuden-api)

(export '(*api-endpoint*
          ))

(defvar *api-endpoint* "http://setsuden.yahooapis.jp/v1/Setsuden/latestPowerUsage"
  "Yahoo �d�͎g�p�� API �� URL")

(defvar *app-id* "yU3Fn0Gxg65IQELBxYmNuQiMvOp5mZ6X2TiK2dLKJqe0uGOsCEbclDPockhGRHQ-")

(defun json->struct-impl (area json)
  (when ($ json :ERROR)
    (error "Yahoo �d�͎g�p�� API �̌Ăяo���Ɏ��s���܂���: ~A" ($ json :ERROR :Message)))
  (let* ((usage ($ json :ElectricPowerUsage))
         (date (mapcar #'parse-integer (split-string ($ usage :Date) #\-)))
         (hour ($ usage :Hour)))
    (make-power :area area
                :datetime (encode-universal-time
                           0 0 hour
                           (third date) (second date) (first date))
                :capacity (/ ($ usage :Capacity :$) 10000)   ; kW �Œ�
                :usage (/ ($ usage :Usage :$) 10000)         ; kW �Œ�
                :entryfor nil
                :capacity-updated nil
                :capacity-peak-period nil
                :usage-updated nil
                :saving-p nil)))

(defun build-api-endpoint-impl (area &optional year month day hour)
  (let ((params `((:appid . ,*app-id*)
                  (:output . :json)
                  (:area . ,area))))
    (when (and year month)
      (push (cons :datetime (format nil "~4,'0D~2,'0D~2,'0D~2,'0D" year month day hour))
            params))
    (xhr::add-query-params *api-endpoint* params)))

(dolist (area '(:tohoku :kansai))
  (add-extension area (make-extension
                       :json->struct 'json->struct-impl
                       :build-api-endpoint 'build-api-endpoint-impl)))


(provide "power-usage/api/yahoo-setsuden-api")

;;; End