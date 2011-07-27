; -*- mode: lisp; package: power-usage.base; encoding: shift-jis -*-

;;; power-usage/api/base.l
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

  (unless (find-package :power-usage.base)
    (defpackage :power-usage.base
      (:use
       :lisp
       :power-usage
       ))

    (use-package :power-usage.base :power-usage)
    ))

(in-package :power-usage.base)

(export '(add-extension
          area-name
          list-supported-area

          $
          parse-response
          build-api-endpoint
          response-text
          response-json

          ;; struct
          make-power
          power-p
          power-area
          power-datetime
          power-capacity
          power-usage
          power-usage-rate
          ))

(defstruct power
  area                          ; 地域 (:tokyo, :tohoku, :kansai, :chubu, :kyushu)
  datetime                      ; 年月日 (ユニバーサルタイム)
  capacity                      ; 供給可能最大電力（万kW）
  usage                         ; この時刻の消費電力（万kW）
  )

;; (((:<area-code> . "<area-name>") . :<package-name>) ...)
(defvar *extensions* nil)


(defun power-usage-rate (power)
  (if (zerop (power-capacity power))
      0
    (* (/ (power-usage power)
          (power-capacity power))
       100.0)))

;; area -> (:<area-code> . "<area-name>")
(defun add-extension (area pkg)
  (let ((ext (cons area pkg)))
    (setf *extensions* (delete ext *extensions* :test 'equalp))
    (push ext *extensions*)))

(defun area-name (area)
  (let ((ext (find-extensions area)))
    (cdaar ext)))

;; ((:<area-code1> . "<area-name1>")
;;  (:<area-code2> . "<area-name2>")
;;  ...)
(defun list-supported-area ()
  (nreverse
   (delete-duplicates (mapcar #'car *extensions*)
                      :key #'car)))

(defun dispatch (symbol area &rest args)
  (dolist (ext (find-extensions area))
    (let ((fn (intern (string symbol) (cdr ext))))
      (when (fboundp fn)
        (return-from dispatch (apply fn area args)))))
  (error "~A には対応していません。" area))

(defun find-extensions (area)
  (let ((exts (remove-if-not #'(lambda (ext)
                                (string= (caar ext) area))
                            *extensions*)))
    (unless exts
      (error "~A には対応していません。" area))
    exts))

(defun $ (json &rest keys)
  (reduce #'(lambda (obj key)
              (cdr (assoc key obj :test #'string=)))
          keys
          :initial-value json))

(defun parse-response (area res &key datetime latest history)
  (let ((fn (cond (history :parse-response-history)
                  (latest :parse-response-latest)
                  (t :parse-response-datetime))))
    (dispatch fn area res)))

(defun build-api-endpoint (area &key datetime latest history)
  (let ((fn (cond (history :build-api-endpoint-history)
                  (latest :build-api-endpoint-latest)
                  (t :build-api-endpoint-datetime))))
    (dispatch fn area datetime)))

(defun response-json (res)
  (json:json-decode (response-text res)))

(defun response-text (res)
  (multiple-value-bind (text status _)
      (xhr:xhr-response-values res)
    (unless (<= 200 status 299)
      (plain-error (format nil "~A ~A" status (xhr:xhr-status-text res))))
    text))


(provide "power-usage/api/base")

;;; End
