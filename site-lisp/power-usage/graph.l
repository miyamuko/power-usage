; -*- mode: lisp; package: power-usage; encoding: shift_jis -*-

;;; power-usage/graph.l
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
  (require "power-usage/macros")
  (require "power-usage/api")
  (require "power-usage/mode")
  )

(in-package :power-usage)

(export '(*power-usage-graph-colors*
          *power-usage-graph-buffer-name*
          *power-usage-graph-buffer-height*
          *power-usage-graph-min-size*
          *power-usage-graph-max-size*
          *power-usage-graph-y-axis-format*
          *power-usage-graph-bar-format*
          *power-usage-graph-bar-date-format*
          *power-usage-graph-bar-char*
          *power-usage-graph-empty-char*
          *power-usage-graph-map*
          *power-usage-graph-window-flags-on*
          *power-usage-graph-window-flags-off*

          show-power-usage-graph
          toggle-auto-refresh-mode
          ))

(defvar *power-usage-graph-colors*
  '((:color 2 :usage 89)  ; 89% 以下の色
    (:color 3 :usage 94)  ; 90% ～  94% の色
    (:color 5 :usage 96)  ; 95% ～  96% の色
    (:color 1 :usage 100) ; 97% 以上の色
    (:color 15 :free t)   ; 電力未使用の領域の色
    )
  "グラフの色の定義。
http://setsuden.yahoo.co.jp/meter/index.html も参照。")

(defvar *power-usage-graph-buffer-name* "*Power Usage*"
  "バッファ名")

(defvar *power-usage-graph-buffer-height* -12
  "バッファの高さ")

(defvar *power-usage-graph-min-size* 30
  "棒グラフの最小の長さ。基本的にはウィンドウサイズにぴったりおさまるように自動調整する")

(defvar *power-usage-graph-max-size* 200
  "棒グラフの最大の長さ。基本的にはウィンドウサイズにぴったりおさまるように自動調整する")

(defvar *power-usage-graph-y-axis-format* "~8A  "
  "会社名のフォーマット")

(defvar *power-usage-graph-bar-format* "~A ~3D%  ~4D/~4D万kW  ~A"
  "棒グラフと供給量などの情報のフォーマット")

(defvar *power-usage-graph-bar-date-format* "%H時%M分"
  "更新時間のフォーマット")

(defvar *power-usage-graph-bar-char* #\#
  "電力使用中の領域のグラフの文字")

(defvar *power-usage-graph-empty-char* #\-
  "電力未使用の領域のグラフの文字")

(defvar *power-usage-graph-map* nil
  "グラフモードのキー定義")
(unless *power-usage-graph-map*
  (setf *power-usage-graph-map*
        (let ((keymap (make-sparse-keymap)))
          (define-key keymap #\q 'quit-power-usage-graph)
          (define-key keymap #\r 'refresh-power-usage-graph)
          (define-key keymap #\a 'toggle-auto-refresh-mode)
          keymap)))

(defvar *power-usage-graph-window-flags-on*
  (list *window-flag-mode-line*
        )
  "グラフバッファで有効にする window flag")

(defvar *power-usage-graph-window-flags-off*
  (list *window-flag-line-number*
        *window-flag-ruler*
        *window-flag-newline*
        *window-flag-tab*
        *window-flag-full-width-space*
        *window-flag-zenkaku-space*
        *window-flag-vscroll-bar*
        *window-flag-eof*
        *window-flag-hscroll-bar*
        ed::*window-flag-function-bar*
        *window-flag-fold-mark*
        *window-flag-cursor-line*
        *window-flag-half-width-space*
        *window-flag-alternate-vscroll-bar*
        *window-flag-scrolling*
        *window-flag-just-inverse*
        *window-flag-fold-line*
        )
    "グラフバッファで無効にする window flag")


(defparameter *power-usage-graph-auto-refresh-p* nil
 "電力使用状況グラフを自動更新するかどうか")


(defun show-power-usage-graph ()
  "電力各社の電力使用状況をグラフ表示します。"
  (interactive)
  (init-power-usage-graph)
  (refresh-power-usage-graph))

(defun power-usage-graph-mode (&optional (buffer (selected-buffer)))
  (with-selected-buffer buffer
    (kill-all-local-variables)
    (toggle-read-only t)
    (dolist (flag *power-usage-graph-window-flags-on*)
      (set-local-window-flags buffer flag t))
    (dolist (flag *power-usage-graph-window-flags-off*)
      (set-local-window-flags buffer flag nil))
    (setf buffer-mode 'power-usage-graph-mode)
    (update-mode-name)
    (use-keymap *power-usage-graph-map*)
    (when *power-usage-graph-auto-refresh-p*
      (start-auto-refresh-mode))
    ))

(defun toggle-auto-refresh-mode (&optional (on nil on-supplied-p))
  (interactive)
  (let ((flag (if on-supplied-p
                  on
                (not *power-usage-graph-auto-refresh-p*))))
    (if flag
        (start-auto-refresh-mode)
      (stop-auto-refresh-mode))
    (setf *power-usage-graph-auto-refresh-p* flag)
    (with-graph-buffer
      (update-mode-name))))

(defun start-auto-refresh-mode ()
  (add-hook '*power-usage-update-hook*
            'on-power-usage-update)
  (add-hook 'ed::*delete-buffer-hook*
            'on-delete-graph-buffer)
  (unless *power-usage-mode*
    (start-power-usage-watcher))
  )

(defun stop-auto-refresh-mode ()
  (delete-hook '*power-usage-update-hook*
               'on-power-usage-update)
  (delete-hook 'ed::*delete-buffer-hook*
               'on-delete-graph-buffer)
  (unless *power-usage-mode*
    (stop-power-usage-watcher))
  )

(defun update-mode-name ()
  (setf mode-name
        (format nil "電力使用状況:自動更新~:[Off~;On~]"
                *power-usage-graph-auto-refresh-p*)))

(defun on-delete-graph-buffer (buffer)
  (when (eq (buffer-local-value buffer 'buffer-mode)
            'power-usage-graph-mode)
    (stop-auto-refresh-mode))
  t)

(defun on-power-usage-update (power)
  (if (find-buffer *power-usage-graph-buffer-name*)
      (refresh-power-usage-graph power)
    (stop-auto-refresh-mode)))

(defun quit-power-usage-graph ()
  (interactive)
  (stop-auto-refresh-mode)
  (delete-buffer (selected-buffer))
  (when (< 1 (count-windows))
    (delete-window)))

(defun init-power-usage-graph ()
  (with-output-to-graph-buffer
    (refresh-screen) ; window-width を確定させるためここで一度レンダリング
    (insert #\SPC #\LFD)   ; あとで render-x-header するためのスペース
    (dolist (area (list-supported-area))
      (render-y-header (cdr area))
      (insert #\LFD #\LFD))
    ;; バッファの最後の余計な改行を削除
    (end-of-buffer)
    (skip-chars-backward "\n")
    (kill-region (point) (point-max))
    (power-usage-graph-mode)))

(defun refresh-power-usage-graph (&optional power)
  (interactive)
  (with-graph-buffer
    (beginning-of-buffer)
    (kill-line)
    (render-x-header)
    (dolist (area (list-supported-area))
      (when (interactive-p)
        (beginning-of-bar (cdr area) :clear t)
        (insert "更新中..."))
      (if (and power (eq (car area) (power-area power)))
          (render-graph power)
        (get-latest-power-usage :area (car area)
                                :callback #'render-graph))))
    (refresh-screen))

(defun render-x-header ()
  (insert (format-y-axis ""))
  (let ((len (calc-bar-length 10)))
    (dotimes (i 10)
      (insert (format nil "~VA" (if (= i 9) 0 len) (* i 10))))))

(defun render-y-header (area-name)
  (insert (format-y-axis area-name)))

(defun render-graph (power)
  (with-graph-buffer
    (beginning-of-bar (area-name (power-area power)) :clear t)
    (insert (format-bar (make-bar (calc-bar-length (power-usage-rate power)))
                        (power-usage-rate power)
                        (power-usage power)
                        (power-capacity power)
                        (power-datetime power)))
    (goto-bol)
    (colorize power)
    (beginning-of-buffer))
  (refresh-screen))

(defun beginning-of-bar (area-name &key clear)
  (goto-char (point-min))
  (scan-buffer (format-y-axis area-name) :tail t)
  (when (and clear (not (eolp)))
    (kill-line)))

(defun colorize (power)
  (when (scan-buffer (make-str 5 *power-usage-graph-bar-char*))
    (let ((start (point)))
      (dolist (color/rate (graph-colors power))
        (let ((color (car color/rate))
              (rate (cdr color/rate)))
          (unless (zerop rate)
            (set-text-attribute start (+ start (calc-bar-length rate)) nil
                                :foreground color :background color)))))))

(defun graph-colors (power)
  (mapcar #'(lambda (color)
              (cons (getf color :color)
                    (cond ((getf color :free)
                           100)
                          ((getf color :usage)
                           (min (getf color :usage)
                                (power-usage-rate power)))
                          (t
                           0))))
          (stable-sort (copy-seq *power-usage-graph-colors*)
                       #'> :key #'color-priority)))

(defun color-priority (color)
  (if (getf color :free)
      100000
    (getf color :usage)))

(defun calc-bar-length (rate &optional (graph-size (calc-graph-size)))
  (floor (* rate (/ graph-size 100))))

(defun calc-graph-size ()
  (let* ((info-len (+ (length (format-y-axis ""))
                      (length (format-bar "" 0 0 0 0))))
         (bar-len (- (window-width)
                     4 ; なんかこのぐらい引かないと入りきらない
                     info-len)))
    ;; x-header が綺麗に揃うように 10 の倍数にする
    (* (floor (/ (max *power-usage-graph-min-size*
                      (min *power-usage-graph-max-size*
                           bar-len))
                 10))
       10)))

(defun format-y-axis (area-name)
  (format nil *power-usage-graph-y-axis-format*
          area-name))

(defun format-bar (bar rate usage capacity datetime)
  (format nil *power-usage-graph-bar-format*
          bar
          (floor rate)
          usage
          capacity
          (format-date-string *power-usage-graph-bar-date-format* datetime)))

(defun make-bar (len &optional (graph-size (calc-graph-size)))
  (format nil "~A~A"
          (make-str len *power-usage-graph-bar-char*)
          (make-str (- graph-size len) *power-usage-graph-empty-char*)))

(defun make-str (len char)
  (make-sequence 'string len :initial-element char))


(provide "power-usage/graph")


;;; End
