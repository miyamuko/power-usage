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
          *power-usage-update-hook*
          *last-power-usage*

          get-latest-power-usage
          get-power-usage-at
          list-latest-power-usage
          list-power-usage-at
          update-power-usage

          ;; struct
          power-datetime
          power-entryfor
          power-capacity
          power-capacity-updated
          power-capacity-peak-period
          power-usage
          power-usage-updated
          power-saving-p
          power-p
          ))

(defvar *power-usage-area* :tokyo
  "対象地域を指定。デフォルトは :tokyo。

:tokyo（東京電力管轄内）
:tohoku（東北電力管轄内）
:kansai（関西電力管轄内）")

(defvar *power-usage-update-hook* nil
  "自動更新時に実行されるフック")

(defparameter *last-power-usage* nil
  "最後に取得した電力消費量 (power 構造体)")


(defun get-latest-power-usage (&optional (area *power-usage-area*))
  "最新の電力使用状況を返します。"
  (get-power-usage-at nil nil nil nil area))

(defun get-power-usage-at (year month day hour &optional (area *power-usage-area*))
  "指定された日時の電力使用状況を返します。"
  (json->struct area
                (xhr:xhr-get (build-api-endpoint area year month day hour)
                             :key 'response-json
                             :nomsg t :since :epoch)))


(defun list-latest-power-usage (&optional (area *power-usage-area*))
  "今月の毎時の電力使用状況を、リストとして返します。"
  (multiple-value-bind (_ _ _ _ month year _)
      (decode-universal-time (get-universal-time))
    (list-power-usage-at year month nil area)))

(defun list-power-usage-at (year month &optional day (area *power-usage-area*))
  "指定された月または日の毎時の電力使用状況を、リストとして返します。"
  (mapcar #'(lambda (json)
              (json->struct area json))
          (xhr:xhr-get (build-api-endpoint area year month day)
                       :key 'response-json
                       :nomsg t :since :epoch)))


(defun update-power-usage (&optional (area *power-usage-area*))
  "非同期で最新の電力使用状況を更新します。
更新後は *last-power-usage* に値が設定され、
*power-usage-update-hook* が呼ばれます。"
  (interactive)
  (xhr:xhr-get-async (build-api-endpoint area)
                     :nomsg t :since :epoch
                     :key 'response-json
                     :onsuccess #'(lambda (json)
                                    (end-update-power-usage area json))))

(defun end-update-power-usage (area json)
  (setf *last-power-usage* (json->struct area json))
  (run-hooks '*power-usage-update-hook*))


(provide "power-usage/api")

;;; End
