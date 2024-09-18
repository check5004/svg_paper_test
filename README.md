# svg_paper_test

このプロジェクトは、FigmaでデザインしたSVGテンプレートを使用して、クライアントサイドでPDF帳票を動的に生成するデモアプリケーションです。[ttskchさんが開発したSVG Paperライブラリ](https://zenn.dev/ttskch/articles/1f1572cfd2e375)を主に使用しています。

### Download
[Download APK](https://drive.google.com/file/d/1OdfcNK5STPAGvzOxWKCcvwkVAqb-ToI2/view?usp=sharing)

### 概要
このアプリケーションは以下の機能を提供します：
1. SVGテンプレートの読み込みと表示
1. テンプレート内の変数の動的置換
1. 生成された帳票のPDF出力
1. 生成された帳票の画像保存（※現在開発中）

### 主な特徴
- Figmaで作成したSVGテンプレートを使用
- クライアントサイドでの動的なデータ置換
- WebViewを使用したSVGの表示
- PDF出力機能

### 使用方法
#### アプリ
1. アプリを起動すると、SVGテンプレートが読み込まれ表示されます。
1. 「変数置換」ボタンをタップすると、サンプルデータがテンプレートに挿入されます。
1. 「PDF保存」ボタンをタップすると、現在表示されている帳票がPDFとして保存され、共有オプションが表示されます。

#### テンプレート作成
1. Figmaで`2100x2970`(A4)のフレームを作成
1. レイアウト作成
   - 変数は英語のみにしないと認識しない可能性がある
   - 変数は`%xxxxx%`の形式にする
   - テーブルなどの変数は`%xxxxx[99]%`形式にする（これはデータ埋め込みの実装次第だが定義しておくべきかなと）
   - SVGに変換するのでアイテムの幅はFigmaデザインが反映されない<br>
     そのためすべて**左寄せ**で変数テキストを設置し、幅と寄せ方向をメモしておく（Figmaならコメントでよさそう）<br>
     ※あとで値、幅、寄せの３種をコードで書く
1. フレームをSVGでエクスポート
   - 設定は下記画像を参照
      > ![image](https://github.com/user-attachments/assets/189a6f42-42e2-4cb9-a626-772c8f0ff406)
1. `assets`フォルダにSVGを配置
1. `sed.ps1`を実行
   > SVG内のID名にアンダーバーを付与したり安全な名前に変更するスクリプト

### 注意事項
- 画像保存機能は現在開発中で、完全には機能していません。
- A4サイズでのみ検証
- 内部処理ではA4サイズの高さが295mmとなっていたので本来の297mmに対応するためCSSを調整しています。
- 使用したライブラリはSVG化したテンプレートをHTMLで描画するものだが、印刷画面で用紙サイズにあるようになっているのでFlutterとの相性が悪い。ムズイ。

### 参考
- [ついに、Webアプリでの帳票印刷のベストプラクティスを編み出しました](https://zenn.dev/ttskch/articles/1f1572cfd2e375)
- [先日編み出した帳票印刷のベストプラクティスをnpmライブラリとして公開しました](https://zenn.dev/ttskch/articles/8ee0eaaabf0657#svg-paper%E8%87%AA%E4%BD%93%E3%81%AE%E5%9F%BA%E6%9C%AC%E7%9A%84%E3%81%AA%E4%BD%BF%E3%81%84%E6%96%B9)
- [SVG Paper ライブラリ](https://github.com/ttskch/svg-paper)
- [SVGテンプレートの準備方法](https://github.com/ttskch/svg-paper/blob/main/docs/how-to-prepare-svg-template.md)

このプロジェクトは、Webテクノロジーを活用したクロスプラットフォームな帳票生成ソリューションのプロトタイプとして開発されています。
