import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SvgToPdfConverter extends StatefulWidget {
  const SvgToPdfConverter({super.key});

  @override
  SvgToPdfConverterState createState() => SvgToPdfConverterState();
}

class SvgToPdfConverterState extends State<SvgToPdfConverter> {
  late final WebViewController _controller;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              _loadingProgress = 1.0;
            });
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      );
    _loadHtmlContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG to PDF Converter'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loadingProgress < 1.0)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _convertToPdfAndPreview,
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }

  Future<void> _loadHtmlContent() async {
    String svgData = await rootBundle.loadString('assets/Template_test.svg');

    // プレースホルダーの置換
    Map<String, String> replacements = {
      '%客会社名%': '株式会社サンプル',
      '%No%': '001',
      '%請求日%': '2023年4月1日',
      '%件名%': 'システム開発費',
      '%支払期限%': '2023年4月30日',
      '%振込先%': '〇〇銀行 △△支店 普通 1234567',
      '%振込先2%': '口座名義：カブシキガイシャサンプル',
      '%自会社名%': '株式会社テック',
      '%自会社郵便番号%': '123-4567',
      '%自会社住所%': '東京都渋谷区〇〇町1-2-3',
      '%自会社TEL%': '03-1234-5678',
      '%担当者名%': '山田太郎',
      '%合計金額%': '¥550,000',
    };

    // 明細行のデータ
    List<Map<String, String>> items = [
      {'摘要': '設計費', '数量': '1', '単位': '式', '単価': '200,000', '金額': '200,000'},
      {'摘要': '開発費', '数量': '1', '単位': '式', '単価': '300,000', '金額': '300,000'},
      {'摘要': 'テスト費', '数量': '1', '単位': '式', '単価': '50,000', '金額': '50,000'},
    ];

    // 明細行の置換
    for (int i = 0; i < 10; i++) {
      if (i < items.length) {
        replacements['%摘要[$i]%'] = items[i]['摘要']!;
        replacements['%数量[$i]%'] = items[i]['数量']!;
        replacements['%単位[$i]%'] = items[i]['単位']!;
        replacements['%単価[$i]%'] = items[i]['単価']!;
        replacements['%金額[$i]%'] = items[i]['金額']!;
      } else {
        // 未使用の行は空白にする
        replacements['%摘要[$i]%'] = '';
        replacements['%数量[$i]%'] = '';
        replacements['%単位[$i]%'] = '';
        replacements['%単価[$i]%'] = '';
        replacements['%金額[$i]%'] = '';
      }
    }

    // プレースホルダーの置換を実行
    replacements.forEach((key, value) {
      svgData = svgData.replaceAll(key, value);
    });

    String htmlData = '''
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>SVG to PDF</title>
        <script src="https://cdn.jsdelivr.net/npm/svg-paper/dist/svg-paper.min.js"></script>
    </head>
    <body>
        <div id="svg-container">
            $svgData
        </div>
        <button onclick="convertToPdf()">PDF化</button>
        <script>
            function convertToPdf() {
                var svg = document.getElementById('svg-container').innerHTML;
                var paper = new SvgPaper(svg);

                // テキストの調整（必要に応じて）
                // paper.adjustText('#selector1', 1000)
                //      .adjustTextarea('#selector2', 600, 300)
                //      .apply();

                var pdf = paper.toPdf();
                var blob = new Blob([pdf], {type: 'application/pdf'});
                var link = document.createElement('a');
                link.href = window.URL.createObjectURL(blob);
                link.download = 'invoice.pdf';
                link.click();
            }
        </script>
    </body>
    </html>
    ''';

    await _controller.loadHtmlString(htmlData);
  }

  Future<void> _convertToPdfAndPreview() async {
    final pdf = await _createPdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<pw.Document> _createPdf() async {
    final pdf = pw.Document();
    final svgData =
        await _controller.runJavaScriptReturningResult('document.getElementById("svg-container").innerHTML;') as String;

    // final font = await PdfGoogleFonts.notoSansJapaneseRegular();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.SvgImage(svg: svgData),
          );
        },
      ),
    );

    return pdf;
  }
}
