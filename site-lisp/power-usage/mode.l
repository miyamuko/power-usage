; -*- mode: lisp; package: power-usage; encoding: shift_jis -*-

;;; power-usage/mode.l
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
  (require "power-usage/api")
  )

(in-package :power-usage)

(export '(*power-usage-update-interval*
          *power-usage-mode-line-format*

          power-usage-mode
          start-power-usage-watcher
          stop-power-usage-watcher
          ))

(defvar *power-usage-update-interval* (* 10 60)
  "�����X�V�̊Ԋu (�f�t�H���g: 1 ����)")

(defvar *power-usage-mode-line-format* "~A/~A��kW:~D%~:[~;:�v���d���{��~]"
  "���[�h���C���ɕ\������t�H�[�}�b�g (�����͏���d�́A�ő�d�́A�g�p���A�v���d���{�����ǂ����j")

(defvar *power-usage-mode* nil)
(defvar *mode-line* nil)



(defun start-power-usage-watcher ()
  (interactive)
  (stop-power-usage-watcher)
  (update-power-usage)
  (start-timer *power-usage-update-interval* 'update-power-usage))

(defun stop-power-usage-watcher ()
  (interactive)
  (stop-timer 'update-power-usage))

(defun power-usage-status (&optional (u *last-power-usage*))
  (when u
    (format nil *power-usage-mode-line-format*
            (power-usage u)
            (power-capacity u)
            (round (* (/ (power-usage u)
                         (power-capacity u))
                      100.0))
            (power-saving-p u))))

(defun update-mode-line-status ()
  (interactive)
  (setf *mode-line* (power-usage-status))
  (update-mode-line t))

(add-hook '*power-usage-update-hook* 'update-mode-line-status)

(defun power-usage-mode (&optional (arg nil sv))
  (interactive "p")
  (ed::toggle-mode '*power-usage-mode* arg sv)
  (cond (*power-usage-mode*
         (start-power-usage-watcher)
         (update-mode-line-status))
        (t
         (stop-power-usage-watcher)
         (update-mode-line t))))

(pushnew '(*power-usage-mode* . *mode-line*) ed:*minor-mode-alist* :key #'car)


(provide "power-usage/mode")


;;; End