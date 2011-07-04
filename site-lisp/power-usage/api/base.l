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
          make-extension

          $
          json->struct
          build-api-endpoint
          response-json

          ;; struct
          make-power
          power-area
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

(defstruct power
  area                          ; �n�� (:tokyo, :kansai, :tohoku)
  datetime                      ; �N���� (���j�o�[�T���^�C��)
  capacity                      ; �����\�ő�d�́i��kW�j
  usage                         ; ���̎����̏���d�́i��kW�j

  ;; �ȉ��� *power-usage-area* �� :tokyo �̏ꍇ�݂̂ɗL��
  entryfor                      ; ���̎����̕�����iUTC�j
  capacity-updated              ; �����\�ő�d�͂����肳�ꂽ�����iUTC�j
  capacity-peak-period          ; �ő�̋����\�͂𔭊�����\��̎����i24���Ԑ��A���{���ԁj�B
                                ; �܂�A�g�����d���g���Ĉꎞ�I�ɍő�\�͂𔭊����鎞���ł��B
  usage-updated                 ; ���̏���d�͂̃f�[�^���X�V���ꂽ�����iUTC�j
  saving-p                      ; ���̎����Ɍv���d�����{����Ă���� t
  )

(defstruct extension
  json->struct
  build-api-endpoint)


(defvar *extensions* nil)


(defun add-extension (area extension)
  (setf *extensions* (delete area *extensions*
                             :test #'string= :key #'car))
  (push (cons area extension) *extensions*))

(defun dispatch (fn area &rest args)
  (let ((ext (find area *extensions*
                   :test #'string= :key #'car)))
    (unless ext
      (error "~A �ɂ͑Ή����Ă��܂���B" area))
    (apply (si:*slot-value (cdr ext) fn) area args)))


(defun $ (json &rest keys)
  (reduce #'(lambda (obj key)
              (cdr (assoc key obj :test #'string=)))
          keys
          :initial-value json))

(defun json->struct (area json)
  (dispatch :json->struct area json))

(defun build-api-endpoint (area &optional year month day hour)
  (dispatch :build-api-endpoint area year month day hour))

(defun response-json (res)
  (multiple-value-bind (text status _)
      (xhr:xhr-response-values res)
    (unless (<= 200 status 299)
      (plain-error (format nil "~A ~A" status (xhr:xhr-status-text res))))
    (json:json-decode text)))


(provide "power-usage/api/base")

;;; End