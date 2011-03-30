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
  (mc-require "power-usage/package")
  )

(in-package :power-usage)

(export '(*power-usage-api-endpoint*
          *power-usage-update-hook*
          *last-power-usage*

          get-power-usage
          update-power-usage
          ))

(defvar *power-usage-api-endpoint* "http://tepco-usage-api.appspot.com/latest.json"
  "東京電力電力供給状況 API の URL")

(defvar *power-usage-update-hook* nil
  "自動更新時に実行されるフック")

(defparameter *last-power-usage* nil
  "最後に取得した電力消費量 (power 構造体)")

(defstruct power
  datetime                      ; 年月日 (ユニバーサルタイム)
  entryfor                      ; この時刻の文字列（UTC）
  capacity                      ; 供給可能最大電力（万kW）
  capacity-updated              ; 供給可能最大電力が決定された日時（UTC）
  usage                         ; この時刻の消費電力（万kW）
  usage-updated                 ; この消費電力のデータが更新された日時（UTC）
  saving-p                      ; この時刻に計画停電が実施されていれば t
  )

(defun get-power-usage ()
  (parse-power-usage (xhr:xhr-get *power-usage-api-endpoint*
                                  :nomsg t :since :epoch)))

(defun update-power-usage ()
  (xhr:xhr-get-async *power-usage-api-endpoint*
                     :nomsg t :since :epoch
                     :onsuccess 'end-update-power-usage))

(defun end-update-power-usage (res)
  (setf *last-power-usage* (parse-power-usage res))
  (run-hooks '*power-usage-update-hook*))

(defun parse-power-usage (res)
  (let ((json (json:json-decode (xhr:xhr-response-text res))))
    (macrolet (($ (json key)
                 `(cdr (assoc ,key ,json :test #'string=))))
      (make-power :datetime (encode-universal-time
                             0 0 ($ json :hour)
                             ($ json :day) ($ json :month) ($ json :year))
                  :entryfor ($ json :entryfor)
                  :capacity ($ json :capacity)
                  :capacity-updated ($ json :capacity_updated)
                  :usage ($ json :usage)
                  :usage-updated ($ json :usage_updated)
                  :saving-p ($ json :saving)))))


(provide "power-usage/api")

;;; End
