# History

----

## 2011/08/12

power-usage 1.3.2 リリース!

  - 新規機能
    - `*power-usage-graph-colors*` に文字色と背景色を別々に指定できるようにした (#13)

        ```lisp
        (setf *power-usage-graph-colors*
          '((:foreground 2  :background 7 :usage 89)  ; 89% 以下の色
            (:foreground 3  :background 7 :usage 94)  ; 90% ～  94% の色
            (:foreground 5  :background 7 :usage 96)  ; 95% ～  96% の色
            (:foreground 1  :background 7 :usage 100) ; 97% 以上の色
            (:foreground 15 :background 7 :free t)    ; 電力未使用領域の色
            ))
        ```

  - バグ修正
    - グラフの自動更新を有効にするとバッファがちらつく問題を修正 (#8)
    - バッファを縦に分割しているときにするとグラフ表示すると変になる問題を修正 (#9)
    - 初回実行時と更新時でグラフの長さが変わる場合がある問題を修正 (#10)
    - ミニバッファにカーソルがある状態で更新するとエラーになる問題を修正 (#11)

----

## 2011/08/07

power-usage 1.3.1 リリース!

  - 新規機能
    - `*power-usage-enable-status-message*` に non-nil を設定すると
      前回取得時から値が変わっている場合にはステータスバーに
      電力使用状況の詳細情報を表示するようにした (#7)
  - バグ修正
    - グラフ表示していると Mark がセットされたり、kill-ring にゴミが yank されたり
      していたのを修正 (#6)

----

## 2011/08/06

power-usage 1.3.0 リリース!

  - 新規機能
    - 電力各社の状況を一覧でグラフ表示機能 (#5)

----

## 2011/07/26

power-usage 1.2.0 リリース!

  - 新規機能
    - 中部電力と九州電力の電力使用状況に対応 (#2, Yahoo 電力使用状況 API を利用)
    - 最新情報の取得に対応 (#3)
  - その他
    - 自動更新の場合はメッセージに詳細情報を表示しないようにした
      `M-x update-power-usage` で手動で更新した場合は表示する
    - 自動更新の間隔のデフォルト値を変更: 30 分 => 5 分
    - 東京電力の場合も Yahoo 電力使用状況 API を利用するように変更
  - 非互換
    - `*last-power-usage*` を削除
    - `*power-usage-update-hook*` のフックには power 構造体を引数で渡す
    - power 構造体から Yahoo API が対応していないスロットを削除
    - `*power-usage-mode-line-format*`, `*power-usage-status-format*`
      から計画停電の情報を削除
    - `*power-usage-status-format*` のフォーマットを見直し

----

## 2011/07/15

power-usage 1.1.1 リリース!

  - バグ修正
    - ダンプからロードしたときに動かなくなっていたのを修正 (#1)

----

## 2011/07/04

power-usage 1.1.0 リリース!

  - 新規機能
    - 東北電力と関西電力の電力使用状況に対応 (Yahoo 電力使用状況 API を利用)
  - その他
    - 自動更新の間隔のデフォルト値を 1 時間から 30 分に変更

----

## 2011/04/04

power-usage 1.0.0 リリース!
