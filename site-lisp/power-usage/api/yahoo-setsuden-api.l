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

(defun json->struct-impl (area json)
  (when ($ json :ERROR)
    (error "Yahoo 電力使用状況 API の呼び出しに失敗しました: ~A" ($ json :ERROR :Message)))
  (let* ((usage ($ json :ElectricPowerUsage))
         (date (mapcar #'parse-integer (split-string ($ usage :Date) #\-)))
         (hour ($ usage :Hour)))
    (make-power :area area
                :datetime (encode-universal-time
                           0 0 hour
                           (third date) (second date) (first date))
                :capacity (/ ($ usage :Capacity :$) 10000)   ; kW 固定
                :usage (/ ($ usage :Usage :$) 10000)         ; kW 固定
                :entryfor nil
                :capacity-updated nil
                :capacity-peak-period nil
                :usage-updated nil
                :saving-p nil)))

(defun build-api-endpoint-impl (area &optional year month day hour)
  (let ((params `((:appid . ,*app-id*)
                  (:output . :json)
                  (:area . ,area))))
    (cond ((every #'null (list year month day hour))
           ;; 最新情報の取得
           ;; datetime パラメータなし
           )
          ((every #'identity (list year month day hour))
           ;; 日付時間指定
           (push (cons :datetime (format nil "~4,'0D~2,'0D~2,'0D~2,'0D" year month day hour))
                 params))
          (t
           ;; 月指定など
           (error "Not supported.")))
    (xhr::add-query-params *api-endpoint* params)))

(dolist (area '((:tohoku . "東北電力")
                (:kansai . "関西電力")
                ))
  (add-extension area :power-usage.yahoo-setsuden-api))


(provide "power-usage/api/yahoo-setsuden-api")

;;; End
