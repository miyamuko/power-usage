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
  )

(in-package :power-usage)

(export '(*power-usage-graph-colors*
          *power-usage-graph-size*
          *power-usage-graph-y-axis-format*
          *power-usage-graph-bar-format*
          *power-usage-graph-buffer-name*
          *power-usage-graph-buffer-height*
          *power-usage-graph-bar-char*
          *power-usage-graph-empty-char*
          *power-usage-graph-map*

          show-power-usage-graph
          ))

(defvar *power-usage-graph-colors*
  '((:color 2 :usage 89)  ; 89% �ȉ��̐F
    (:color 3 :usage 94)  ; 90% �`  94% �̐F
    (:color 5 :usage 96)  ; 95% �`  96% �̐F
    (:color 1 :usage 100) ; 97% �ȏ�̐F
    (:color 15 :free t)   ; �d�͖��g�p�̗̈�̐F
    )
  "�O���t�̐F�̒�`�B
http://setsuden.yahoo.co.jp/meter/index.html ���Q�ƁB")

(defvar *power-usage-graph-buffer-name* "*Power Usage*"
  "�o�b�t�@��")

(defvar *power-usage-graph-buffer-height* -12
  "�o�b�t�@�̍���")

(defvar *power-usage-graph-size* 50
  "�_�O���t�̒���")

(defvar *power-usage-graph-y-axis-format* "~8A  "
  "��Ж��̃J������")

(defvar *power-usage-graph-bar-format* "~A ~3D%  ~4D/~4D��kW  ~A"
  "�_�O���t�Ƌ����ʂȂǂ̏��̃t�H�[�}�b�g")

(defvar *power-usage-graph-bar-date-format* "%H��%M��"
  "�X�V���Ԃ̃t�H�[�}�b�g")

(defvar *power-usage-graph-bar-char* #\#
  "�d�͎g�p���̗̈�̃O���t�̕���")

(defvar *power-usage-graph-empty-char* #\SPC
  "�d�͖��g�p�̗̈�̃O���t�̕���")

(defvar *power-usage-auto-refresh-p* nil)

(defvar *power-usage-graph-map*
  (or *power-usage-graph-map*
      (let ((keymap (make-sparse-keymap)))
        (define-key keymap #\q 'quit-power-usage-graph)
        (define-key keymap #\r 'refresh-power-usage-graph)
        (define-key keymap #\a 'toggle-auto-refresh-mode)
        keymap))
  "�O���t���[�h�̃L�[��`")


(defun show-power-usage-graph ()
  "�d�͊e�Ђ̓d�͎g�p�󋵂��O���t�\�����܂��B"
  (interactive)
  (if (find-buffer *power-usage-graph-buffer-name*)
      (refresh-power-usage-graph)
    (init-power-usage-graph)))

(defun power-usage-graph-mode (&optional (buffer (selected-buffer)))
  (with-selected-buffer buffer
    (kill-all-local-variables)
    (toggle-read-only t)
    (setf buffer-mode 'power-usage-graph-mode)
    (update-mode-name)
    (use-keymap *power-usage-graph-map*)
    ))

(defun toggle-auto-refresh-mode ()
  (interactive)
  (if *power-usage-auto-refresh-p*
      (stop-auto-refresh-mode)
    (start-auto-refresh-mode))
  (with-graph-buffer
    (update-mode-name)))

(defun start-auto-refresh-mode ()
  (stop-timer 'auto-refresh-power-usage-graph)
  (start-timer *power-usage-update-interval*
               'auto-refresh-power-usage-graph)
  (setf *power-usage-auto-refresh-p* t))

(defun stop-auto-refresh-mode ()
  (stop-timer 'auto-refresh-power-usage-graph)
  (setf *power-usage-auto-refresh-p* nil))

(defun update-mode-name ()
  (setf mode-name
        (format nil "�d�͎g�p��:�����X�V~:[Off~;On~]"
                *power-usage-auto-refresh-p*)))

(defun auto-refresh-power-usage-graph ()
  (interactive)
  (if (find-buffer *power-usage-graph-buffer-name*)
      (refresh-power-usage-graph)
    (stop-auto-refresh-mode)))

(defun quit-power-usage-graph ()
  (interactive)
  (stop-auto-refresh-mode)
  (delete-buffer (selected-buffer))
  (when (< 1 (count-windows))
    (delete-window)))

(defun init-power-usage-graph ()
  (with-output-to-graph-buffer
    (render-x-header)
    (dolist (area (list-supported-area))
      (render-y-header (cdr area))
      (format t "~%~%"))
    ;; �o�b�t�@�̍Ō�̗]�v�ȉ��s���폜
    (end-of-buffer)
    (skip-chars-backward "\n")
    (kill-region (point) (point-max))
    (power-usage-graph-mode))
  (refresh-power-usage-graph))

(defun refresh-power-usage-graph ()
  (interactive)
  (with-graph-buffer
    (dolist (area (list-supported-area))
      (when (interactive-p)
        (beginning-of-bar (cdr area) :clear t)
        (unless (char= #\SPC (char-before (point)))
          (insert "  "))
        (insert "�X�V��..."))
      (get-latest-power-usage :area (car area)
                              :callback #'render-graph)))
    (refresh-screen))

(defun render-x-header ()
  (format t *power-usage-graph-y-axis-format* "")
  (let ((len (calc-bar-length 11)))
    (dotimes (i 10)
      (format t "~VA" (if (= i 9) 0 len) (* i 10)))
    (terpri)))

(defun render-y-header (area-name)
  (format t *power-usage-graph-y-axis-format*
          area-name))

(defun render-graph (power)
  (with-graph-buffer
    (beginning-of-bar (area-name (power-area power)) :clear t)
    (insert (format nil *power-usage-graph-bar-format*
                    (make-bar (calc-bar-length (power-usage-rate power)))
                    (floor (power-usage-rate power))
                    (power-usage power)
                    (power-capacity power)
                    (format-date-string *power-usage-graph-bar-date-format* (power-datetime power))
                    ))
    (goto-bol)
    (colorize power)
    (beginning-of-buffer))
  (refresh-screen))

(defun beginning-of-bar (area-name &key clear)
  (goto-char (point-min))
  (scan-buffer area-name :tail t)
  (skip-chars-forward " ")
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

(defun calc-bar-length (rate &optional (graph-size *power-usage-graph-size*))
  (floor (* rate (/ graph-size 100))))

(defun make-bar (len &optional (graph-size *power-usage-graph-size*))
  (format nil "~A~A"
          (make-str len *power-usage-graph-bar-char*)
          (make-str (- graph-size len) *power-usage-graph-empty-char*)))

(defun make-str (len char)
  (make-sequence 'string len :initial-element char))


(provide "power-usage/graph")


;;; End