import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

final _player = AudioPlayer();

Future<void> handleScan(BuildContext context, String code) async {
  // проигрываем короткий звуковой сигнал
  await _player.play(AssetSource('sounds/beep.mp3'));

  // при необходимости подмените адрес на свой
  final url = "http://192.168.0.144:5002/edit/$code";

  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => WebViewScreen(url: url)),
  );
}

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _web;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // без AppBar — чистый WebView на весь экран
      body: Stack(
        children: [
          WebViewWidget(controller: _web),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),

      // Кнопка "Сканировать ещё" снизу слева
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Сканировать ещё'),
        backgroundColor: Colors.green, // цвет фона кнопки
        foregroundColor: Colors.white, // цвет текста и иконки
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
