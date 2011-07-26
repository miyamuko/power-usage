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
          *power-usage-datetime-format*

          power-usage-mode
          start-power-usage-watcher
          stop-power-usage-watcher
          ))

(defvar *power-usage-update-interval* (* 10 30)
  "自動更新の間隔 (デフォルト: 30 分)")

(defvar *power-usage-mode-line-format* "~A/~A万kW:~D%~:[~;:計画停電実施中~]"
  "モードラインに表示するフォーマット (引数は消費電力、最大電力、使用率、計画停電実施中かどうか）")

(defvar *power-usage-status-format* "~A/~A万kW (~4,1F%) ~A 計画停電:~:[実施なし~;実施中~] 時刻:~A"
  "モードラインに表示するフォーマット (引数は消費電力、最大電力、使用率、地域、計画停電実施中かどうか、時刻）")

(defvar *power-usage-datetime-format* "%Y/%m/%d %H時台"
  "ステータスバーに表示する時刻")

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
            (floor (power-usage-rate u))
            (power-saving-p u))))

(defun power-usage-long-status (&optional (u *last-power-usage*))
  (when u
    (format nil *power-usage-status-format*
            (power-usage u)
            (power-capacity u)
            (power-usage-rate u)
            (area-name (power-area u))
            (power-saving-p u)
            (format-date-string *power-usage-datetime-format* (power-datetime u)))))

(defun update-mode-line-status ()
  (interactive)
  (let ((status (power-usage-status))
        (long-status (power-usage-long-status)))
    (when status
      (setf *mode-line* (power-usage-status))
      (update-mode-line t)
      (refresh-screen))
    (when long-status
      (message long-status))))

(add-hook '*power-usage-update-hook* 'update-mode-line-status)

(defun power-usage-mode (&optional (arg nil sv))
  (interactive "p")
  (ed::toggle-mode '*power-usage-mode* arg sv)
  (cond (*power-usage-mode*
         ;; 通信中にダンプされないようにタイマで実行
         (start-timer 0.1 'start-power-usage-watcher t))
        (t
         (stop-power-usage-watcher)
         (update-mode-line t))))

(pushnew '(*power-usage-mode* . *mode-line*) ed:*minor-mode-alist* :key #'car)

;; ダンプからロードしたときにタイマを再開
(defun restart-power-usage-mode ()
  (when *power-usage-mode*
    (start-power-usage-watcher)))
(add-hook '*post-startup-hook* 'restart-power-usage-mode)


(provide "power-usage/mode")


;;; End
