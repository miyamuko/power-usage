# power-usage - 電力使用状況をモードラインに表示

* Home URL: <http://miyamuko.s56.xrea.com/xyzzy/power-usage/intro.htm>
* Version: 1.3.2


## SYNOPSIS

モードラインに表示:

1. `*power-usage-area*` で地域を指定 (:tokyo, :tohoku, :kansai, :chubu, :kyusyu)
2. `*power-usage-update-interval*` で監視間隔を秒単位で設定 (デフォルトは 300 秒 (5 分))
3. `*power-usage-mode-line-format*` でモードラインをお好みで設定
4. `M-x power-usage-mode` でモードラインへの表示をトグル

グラフ表示:

1. `*power-usage-graph-colors*` でグラフの色をお好みで設定
2. `M-x show-power-usage-graph` で電力各社の状況を一覧でグラフ表示


## DESCRIPTION

power-usage は東京電力・東北電力・関西電力・中部電力・九州電力の電力使用状況を
xyzzy のモードラインに表示します。

最新のデータは [Yahoo! 電力使用状況 API] から取得します。
過去のデータは [東京電力電力供給状況 API] から取得します（東京電力のみ）。

  [Yahoo! 電力使用状況 API]: http://developer.yahoo.co.jp/webapi/shinsai/setsuden/v1/latestpowerusage.html
  [東京電力電力供給状況 API]: http://tepco-usage-api.appspot.com/


## INSTALL

1. [NetInstaller] で power-usage, xml-http-request, json をインストールします。

2. ni-autoload を利用していない場合は、
   ~/.xyzzy または site-lisp/siteinit.l に以下のコードを追加します。

    ```lisp
    (require "power-usage")
    (power-usage:power-usage-mode t)
    ```

    ※ ni-autoload を利用している場合は設定は不要です。

3. お好みで設定します。

    ```lisp
    ;; 東京電力 (デフォルト)
    ; (setf power-usage:*power-usage-area* :tokyo)
    ;; 東北電力
    ; (setf power-usage:*power-usage-area* :tohoku)
    ;; 関西電力
    ; (setf power-usage:*power-usage-area* :kansai)
    ;; 中部電力
    ; (setf power-usage:*power-usage-area* :chubu)
    ;; 九州電力
    ; (setf power-usage:*power-usage-area* :kyushu)

    ;; ステータスバーに詳細情報を表示する
    ; (setf power-usage:*power-usage-enable-status-message* t)
    ```

4. 設定を反映させるため xyzzy を再起動してください。

    ※siteinit.l に記述した場合には再ダンプが必要です。


## TODO

なし。


## KNOWN BUGS

なし。

要望やバグは [GitHub Issues] か [@miyamuko] まで。


## AUTHOR

みやむこ かつゆき (<mailto:miyamuko@gmail.com>)


## COPYRIGHT

power-usage は MIT/X ライセンスに従って本ソフトウェアを使用、再配布することができます。

    Copyright (c) 2011-2012 MIYAMUKO Katsuyuki.

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



  [NetInstaller]: http://www7a.biglobe.ne.jp/~hat/xyzzy/ni.html
  [GitHub Issues]: http://github.com/miyamuko/power-usage/issues
  [@miyamuko]: http://twitter.com/home?status=%40miyamuko%20%23xyzzy%20power-usage%3a%20
