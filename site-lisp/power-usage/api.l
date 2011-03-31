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
  )

(in-package :power-usage)

(export '(*power-usage-api-endpoint*
          *power-usage-update-hook*
          *last-power-usage*

          get-latest-power-usage
          get-power-usage-at
          list-latest-power-usage
          list-power-usage-at
          update-power-usage
          ))

(defvar *power-usage-api-endpoint* "http://tepco-usage-api.appspot.com"
  "東京電力電力供給状況 API の URL")

(defvar *power-usage-api-latest-path* "latest.json"
  "最新の電力使用状況を返す API のパス")

(defvar *power-usage-api-datetime-path* "~4,'0D/~2,'0D~@[/~2,'0D~]~@[/~2,'0D~].json"
  "指定した日付の電力使用状況を返す API のパス")

(defvar *power-usage-update-hook* nil
  "自動更新時に実行されるフック")

(defparameter *last-power-usage* nil
  "最後に取得した電力消費量 (power 構造体)")


(defstruct power
  datetime                      ; 年月日 (ユニバーサルタイム)
  entryfor                      ; この時刻の文字列（UTC）
  capacity                      ; 供給可能最大電力（万kW）
  capacity-updated              ; 供給可能最大電力が決定された日時（UTC）
  capacity-peak-period          ; 最大の供給能力を発揮する予定の時刻（24時間制、日本時間）。
                                ; つまり、揚水発電を使って一時的に最大能力を発揮する時刻です。
  usage                         ; この時刻の消費電力（万kW）
  usage-updated                 ; この消費電力のデータが更新された日時（UTC）
  saving-p                      ; この時刻に計画停電が実施されていれば t
  )


(defun get-latest-power-usage ()
  "最新の電力使用状況を返します。"
  (get-power-usage-at nil nil nil nil))

(defun get-power-usage-at (year month day hour)
  "指定された日時の電力使用状況を返します。"
  (json->struct (xhr:xhr-get (build-api-endpoint year month day hour)
                             :key 'response-json
                             :nomsg t :since :epoch)))


(defun list-latest-power-usage ()
  "今月の毎時の電力使用状況を、リストとして返します。"
  (multiple-value-bind (_ _ _ _ month year _)
      (decode-universal-time (get-universal-time))
    (list-power-usage-at year month)))

(defun list-power-usage-at (year month &optional day)
  "指定された月または日の毎時の電力使用状況を、リストとして返します。"
  (mapcar #'json->struct
          (xhr:xhr-get (build-api-endpoint year month day)
                       :key 'response-json
                       :nomsg t :since :epoch)))


(defun update-power-usage ()
  "非同期で最新の電力使用状況を更新します。
更新後は *last-power-usage* に値が設定され、
*power-usage-update-hook* が呼ばれます。"
  (interactive)
  (xhr:xhr-get-async (build-api-endpoint)
                     :nomsg t :since :epoch
                     :key 'response-json
                     :onsuccess 'end-update-power-usage))

(defun end-update-power-usage (json)
  (setf *last-power-usage* (json->struct json))
  (run-hooks '*power-usage-update-hook*))


(defun json->struct (json)
  (macrolet (($ (json key)
               `(cdr (assoc ,key ,json :test #'string=))))
    (make-power :datetime (encode-universal-time
                           0 0 ($ json :hour)
                           ($ json :day) ($ json :month) ($ json :year))
                :entryfor ($ json :entryfor)
                :capacity ($ json :capacity)
                :capacity-updated ($ json :capacity_updated)
                :capacity-peak-period ($ json :capacity_peak_period)
                :usage ($ json :usage)
                :usage-updated ($ json :usage_updated)
                :saving-p ($ json :saving))))

(defun response-json (res)
  (multiple-value-bind (text status _)
      (xhr:xhr-response-values res)
    (unless (<= 200 status 299)
      (plain-error (format nil "~A ~A" status (xhr:xhr-status-text res))))
    (json:json-decode text)))


(defun build-api-endpoint (&optional year month day hour)
  (let ((path (if (and year month)
                  (format nil *power-usage-api-datetime-path* year month day hour)
                *power-usage-api-latest-path*)))
    (build-url path)))

(defun build-url (path)
  (format nil "~A/~A" *power-usage-api-endpoint* path))



(provide "power-usage/api")

;;; End
