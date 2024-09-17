import 'package:flutter/material.dart';

import 'svg_to_pdf_converter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Svg to Pdf Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Svg to Pdf Converter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Key _svgToPdfConverterKey = UniqueKey();

  void _resetSvgToPdfConverter() {
    setState(() {
      _svgToPdfConverterKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSvgToPdfConverter,
            tooltip: 'リセット',
          ),
        ],
      ),
      body: SvgToPdfConverter(key: _svgToPdfConverterKey),
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
    );
  }
}
