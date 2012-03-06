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
  "Yahoo 電力使用状況 API の URL")

(defvar *app-id* "yU3Fn0Gxg65IQELBxYmNuQiMvOp5mZ6X2TiK2dLKJqe0uGOsCEbclDPockhGRHQ-")

(defun parse-response-latest (area res)
  (parse-response-impl area (response-json res)))

(defun parse-response-datetime (area res)
  (parse-response-impl area (response-json res)))

(defun parse-response-impl (area json)
  (when ($ json :ERROR)
    (error "Yahoo 電力使用状況 API の呼び出しに失敗しました: ~A" ($ json :ERROR :Message)))
  (let* ((usage ($ json :ElectricPowerUsage))
         (date (mapcar #'parse-integer (split-string ($ usage :Date) #\-)))
         (hour ($ usage :Hour))
         (minutes ($ usage :Min)))
    (make-power :area area
                :datetime (encode-universal-time
                           0 (or minutes 0) hour
                           (third date) (second date) (first date))
                :capacity (/ ($ usage :Capacity :$) 10000)   ; kW 固定
                :usage (/ ($ usage :Usage :$) 10000)         ; kW 固定
                )))

(defun build-api-endpoint-latest (area datetime)
  (build-api-endpoint-impl area '(:latest 1)))

(defun build-api-endpoint-datetime (area datetime)
  (let ((datetime-str (apply 'format nil "~4,'0D~2,'0D~2,'0D~2,'0D" datetime)))
    (build-api-endpoint-impl area (cons :datetime datetime-str))))

(defun build-api-endpoint-impl (area param)
  (let ((params `((:appid . ,*app-id*)
                  (:output . :json)
                  (:area . ,area))))
    (push param params)
    (xhr::add-query-params *api-endpoint* params)))

(dolist (area '((:tokyo  . "東京電力")
                (:tohoku . "東北電力")
                (:kansai . "関西電力")
                (:chubu  . "中部電力")
                (:kyushu . "九州電力")
                ))
  (add-extension area :power-usage.yahoo-setsuden-api))


(provide "power-usage/api/yahoo-setsuden-api")

;;; End
