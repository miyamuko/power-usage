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
          *power-usage-update-hook*

          power-usage-mode
          start-power-usage-watcher
          stop-power-usage-watcher
          ))

(defvar *power-usage-update-interval* (* 5 60)
  "自動更新の間隔を秒単位で指定 (デフォルト: 5 分)")

(defvar *power-usage-mode-line-format* "~A/~A万kW:~D%"
  "モードラインに表示するフォーマット (引数は消費電力、最大電力、使用率）")

(defvar *power-usage-status-format* "~A ~A ~A/~A万kW (~4,1F%)"
  "モードラインに表示するフォーマット (引数は時刻、地域、消費電力、最大電力、使用率）")

(defvar *power-usage-datetime-format* "%Y/%m/%d %H:%M"
  "ステータスバーに表示する時刻")

(defvar *power-usage-update-hook* nil
  "自動更新時に実行されるフック")

(defvar *power-usage-mode* nil)
(defvar *mode-line* nil)


(defun update-power-usage (&optional (area *power-usage-area*))
  "非同期で最新の電力使用状況を更新します。
更新後は power 構造体を引数にして *power-usage-update-hook* に
設定したフックが呼ばれます。"
  (interactive)
  (let ((show-message-p (interactive-p)))
    (xhr:xhr-get-async (build-api-endpoint area :latest t)
                       :nomsg t :since :epoch
                       :onsuccess #'(lambda (res)
                                      (end-update-power-usage area res show-message-p)))))

(defun end-update-power-usage (area res show-message-p)
  (let ((power (parse-response area res :latest t)))
    (update-mode-line-status power show-message-p)
    (run-hook-with-args '*power-usage-update-hook* power)))


(defun start-power-usage-watcher ()
  (interactive)
  (stop-power-usage-watcher)
  (update-power-usage)
  (start-timer *power-usage-update-interval* 'update-power-usage))

(defun stop-power-usage-watcher ()
  (interactive)
  (stop-timer 'update-power-usage))

(defun power-usage-status (power)
  (when power
    (format nil *power-usage-mode-line-format*
            (power-usage power)
            (power-capacity power)
            (floor (power-usage-rate power))
            )))

(defun power-usage-long-status (power)
  (when power
    (format nil *power-usage-status-format*
            (format-date-string *power-usage-datetime-format* (power-datetime power))
            (area-name (power-area power))
            (power-usage power)
            (power-capacity power)
            (power-usage-rate power)
            )))

(defun update-mode-line-status (power show-message-p)
  (let ((status (power-usage-status power))
        (long-status (power-usage-long-status power)))
    (when status
      (setf *mode-line* status)
      (update-mode-line t)
      (refresh-screen))
    (when (and show-message-p long-status)
      (message long-status))))

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
