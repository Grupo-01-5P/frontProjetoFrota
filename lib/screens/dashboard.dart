import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Só importe para mobile
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui; // Necessário para registrar o iframe view
import 'dart:html' as html;

import 'package:webview_flutter/webview_flutter.dart'; // Funciona só em Android/iOS

class PowerBIPage extends StatefulWidget {
  const PowerBIPage({super.key});

  @override
  State<PowerBIPage> createState() => _PowerBIPageState();
}

class _PowerBIPageState extends State<PowerBIPage> {
  final String powerBiUrl =
      "https://app.powerbi.com/view?r=eyJrIjoiNTlkNDFhNTAtYTFhNy00NDk4LTkxZDUtZjg4ZWQwZDczMzFmIiwidCI6IjRmODUzZjYzLTBlNjUtNGU0Ny05M2Q4LTFhMjk3YzQxODRmOCJ9";

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // Registrar o iframe como um elemento HTML
      // Um ID único para o iframe
      const String viewID = 'powerbi-iframe';

      // Cria o iframe
      final iframe = html.IFrameElement()
        ..src = powerBiUrl
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%'
        ..allowFullscreen = true;

      // Registra o iframe como um widget
      ui.platformViewRegistry.registerViewFactory(
        viewID,
        (int viewId) => iframe,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Frota")),
      body: kIsWeb
          ? const HtmlIframeWidget()
          : const MobileWebViewWidget(),
    );
  }
}

// Widget para Flutter Web (iframe)
class HtmlIframeWidget extends StatelessWidget {
  const HtmlIframeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'powerbi-iframe');
  }
}

// Widget para Android/iOS (webview_flutter)
class MobileWebViewWidget extends StatelessWidget {
  const MobileWebViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
          "https://app.powerbi.com/view?r=eyJrIjoiNTlkNDFhNTAtYTFhNy00NDk4LTkxZDUtZjg4ZWQwZDczMzFmIiwidCI6IjRmODUzZjYzLTBlNjUtNGU0Ny05M2Q4LTFhMjk3YzQxODRmOCJ9"));

    return WebViewWidget(controller: controller);
  }
}
