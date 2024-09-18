import 'package:flutter/material.dart';
import 'package:html_to_pdf/html_to_pdf.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

class SvgToPdfConverter extends StatefulWidget {
  const SvgToPdfConverter({super.key});

  @override
  SvgToPdfConverterState createState() => SvgToPdfConverterState();
}

class SvgToPdfConverterState extends State<SvgToPdfConverter> {
  late final WebViewController _controller;
  final ScreenshotController _screenshotController = ScreenshotController();
  double _loadingProgress = 0.0;
  bool _isLoaded = false;

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
          onPageFinished: (String url) async {
            setState(() {
              _loadingProgress = 1.0;
              _isLoaded = true;
            });
            await _initializeSvgPaper();
          },
          onWebResourceError: (WebResourceError error) {
            print('WebViewエラー: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) {
          print('JavaScriptからのメッセージ: ${message.message}');
        },
      );
    _loadHtmlContent();
  }

  Future<void> _loadHtmlContent() async {
    String svgData = await rootBundle.loadString('assets/Template_test_sed.svg');
    String htmlData = '''
    <!DOCTYPE html>
    <html lang="ja">
    <head>
      <meta charset="UTF-8">
      <title>SVG to PDF</title>
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/svg-paper/dist/svg-paper.min.css">
      <script src="https://cdn.jsdelivr.net/npm/svg-paper/dist/svg-paper.min.js"></script>
      <style>
      @page { size: A4; }
      .paper.A4 svg { height: auto; }
      </style>
    </head>
    <body>
      <div class="paper A4">
        $svgData
      </div>
      <script>
        let paper;
        function initializeSvgPaper() {
          try {
            paper = new SvgPaper('.paper > svg');
            Flutter.postMessage('SvgPaper initialized');
          } catch (error) {
            Flutter.postMessage('Error initializing SvgPaper: ' + error.message);
          }
        }
        function replaceVariables(replacements) {
          if (!paper) {
            Flutter.postMessage('Error: SvgPaper not initialized');
            return;
          }
          try {
            for (const [key, value] of Object.entries(replacements)) {
              paper.replace(key, value);
            }
            paper.apply();
            Flutter.postMessage('Variables replaced');
          } catch (error) {
            Flutter.postMessage('Error replacing variables: ' + error.message);
          }
        }
      </script>
    </body>
    </html>
    ''';
    await _controller.loadHtmlString(htmlData);
  }

  Future<void> _initializeSvgPaper() async {
    await _controller.runJavaScript('initializeSvgPaper()');
  }

  Future<void> _replaceVariables() async {
    final replacements = createReplacements();
    String jsonReplacements = jsonEncode(replacements);
    await _controller.runJavaScript('''
    function replaceAndAdjustVariables(replacements) {
      if (!paper) {
        Flutter.postMessage('Error: SvgPaper not initialized');
        return;
      }
      try {
        for (const [key, value] of Object.entries(replacements)) {
          paper.replace('%' + key + '%', value.text);
          if (value.width) {
            paper.adjustText('#_' + key.replaceAll('[', '_').replaceAll(']', '') + '_', value.width, value.align || 'start');
          }
        }
        paper.apply();
        Flutter.postMessage('Variables replaced and adjusted');
      } catch (error) {
        Flutter.postMessage('Error replacing and adjusting variables: ' + error.message);
      }
    }
    replaceAndAdjustVariables($jsonReplacements);
  ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black38,
        child: Column(
          children: [
            if (_loadingProgress < 1.0)
              LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            Expanded(
              child: Screenshot(
                controller: _screenshotController,
                child: WebViewWidget(controller: _controller),
              ),
            ),
            if (_isLoaded)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _replaceVariables,
                      child: const Text('変数置換'),
                    ),
                    ElevatedButton(
                      onPressed: _saveAsPdf,
                      child: const Text('PDF保存'),
                    ),
                    ElevatedButton(
                      onPressed: _saveAsImage,
                      child: const Text('画像保存'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAsPdf() async {
    try {
      var printViewHtml = await _controller.runJavaScriptReturningResult(r'''
        (function() {
          try {
            return document.documentElement.outerHTML;
          } catch (error) {
            return 'Error getting HTML: ' + error.toString();
          }
        })();
      ''') as String;

      // Dart側でデコード
      printViewHtml = _decodeHtml(printViewHtml);

      print('HTML length: ${printViewHtml.length}');
      print('HTML preview: ${printViewHtml.substring(0, min(200, printViewHtml.length))}');

      if (printViewHtml.startsWith('Error')) {
        throw Exception(printViewHtml);
      }

      final output = await getTemporaryDirectory();
      final targetPath = output.path;
      const targetFileName = 'document';

      final generatedPdfFile = await HtmlToPdf.convertFromHtmlContent(
        htmlContent: printViewHtml,
        printPdfConfiguration: PrintPdfConfiguration(
          targetDirectory: targetPath,
          targetName: targetFileName,
          printSize: PrintSize.A4,
          printOrientation: PrintOrientation.Portrait,
        ),
      );

      await Share.shareXFiles([XFile(generatedPdfFile.path)], text: 'PDF文書を共有');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDFを保存しました')),
      );
    } catch (e) {
      print('PDF保存エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDFの保存に失敗しました')),
      );
    }
  }

  Future<void> _saveAsImage() async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/document.png');
        await file.writeAsBytes(imageBytes);
        await Share.shareXFiles([XFile(file.path)], text: '画像を共有');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像を保存しました')),
        );
      }
    } catch (e) {
      print('画像保存エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像の保存に失敗しました')),
      );
    }
  }
}

String _decodeHtml(String html) {
  // 最初と最後のダブルクォーテーションを削除
  if (html.startsWith('"') && html.endsWith('"')) {
    html = html.substring(1, html.length - 1);
  }

  // JavaScriptの文字列リテラルをデコード
  html = html.replaceAll('\\"', '"').replaceAll('\\n', '\n');

  // Unicodeエスケープシーケンスをデコード
  var decoded = html.replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'), (match) {
    return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
  });

  // HTMLエンティティをデコード
  decoded = HtmlUnescape().convert(decoded);

  return decoded;
}

Map<String, Map<String, Object>> createReplacements() {
  final baseReplacements = {
    '客会社名': {'text': '株式会社サンプル', 'width': 704},
    'No': {'text': '001', 'width': 352, 'align': 'end'},
    'BillingDate': {'text': '2023年5月1日', 'width': 352, 'align': 'end'},
    '件名': {'text': 'サンプル請求書', 'width': 880},
    '支払期限': {'text': '2023年5月31日', 'width': 880},
    '振込先': {'text': 'サンプル銀行 東京支店 普通', 'width': 880},
    '振込先2': {'text': '1234567', 'width': 880},
    '請求先名': {'text': '株式会社テスト', 'width': 704, 'align': 'start'},
    '請求先住所': {'text': '東京都渋谷区サンプル町1-2-3', 'width': 1056, 'align': 'start'},
    '請求先TEL': {'text': '03-1234-5678', 'width': 528, 'align': 'end'},
    '合計金額': {'text': '¥550,000', 'width': 528, 'align': 'end'},
    '自会社名': {'text': '株式会社 東計電算', 'width': 704, 'align': 'end'},
    '自会社郵便番号': {'text': '150-0000', 'width': 352, 'align': 'end'},
    '自会社住所': {'text': '東京都渋谷区サンプル町1-2-3', 'width': 1056, 'align': 'end'},
    '自会社TEL': {'text': '03-1234-5678', 'width': 528, 'align': 'end'},
    '担当者名': {'text': '山田太郎', 'width': 528, 'align': 'end'},
  };

  final items = [
    {'摘要': '商品A', 'Num': '2', 'Unit': '個', 'UnitPrice': '¥100,000', 'AmountOfMoney': '¥200,000'},
    {'摘要': '商品B', 'Num': '1', 'Unit': '個', 'UnitPrice': '¥1,500', 'AmountOfMoney': '¥1,500'},
    {'摘要': '商品C', 'Num': '4', 'Unit': '個', 'UnitPrice': '¥50,000', 'AmountOfMoney': '¥200,000'},
    {'摘要': '商品D', 'Num': '3', 'Unit': '個', 'UnitPrice': '¥30,000', 'AmountOfMoney': '¥90,000'},
    {'摘要': '商品E', 'Num': '2', 'Unit': '個', 'UnitPrice': '¥20,000', 'AmountOfMoney': '¥40,000'},
  ];

  for (var i = 0; i <= 10; i++) {
    final item = i < items.length ? items[i] : {'摘要': '', 'Num': '', 'Unit': '', 'UnitPrice': '', 'AmountOfMoney': ''};
    baseReplacements.addAll({
      '摘要[$i]': {'text': item['摘要'] ?? '', 'width': 165, 'align': 'start'},
      'Num[$i]': {'text': item['Num'] ?? '', 'width': 165, 'align': 'end'},
      'Unit[$i]': {'text': item['Unit'] ?? '', 'width': 180, 'align': 'middle'},
      'UnitPrice[$i]': {'text': item['UnitPrice'] ?? '', 'width': 334, 'align': 'end'},
      'AmountOfMoney[$i]': {'text': item['AmountOfMoney'] ?? '', 'width': 324, 'align': 'end'},
    });
  }

  return baseReplacements;
}

// 使用例
final replacements = createReplacements();
