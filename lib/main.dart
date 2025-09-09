import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scan_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScannerScreen(),
    );
  }
}

/// Экран сканера: распознаём только внутри рамки (scanWindow),
/// после первого кода — останавливаем камеру, открываем WebView,
/// по возврату — снова запускаем камеру.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _handling = true;
    await _controller.stop(); // стопим камеру, чтобы не было повторных срабатываний

    try {
      await handleScan(context, code); // откроет WebView
    } finally {
      if (!mounted) return;
      _handling = false;
      await _controller.start(); // вернулись из WebView — запускаем снова
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // ---- Настройки окна сканирования ----
          final cutWidth  = w * 0.85;   // ширина окна ~85% экрана
          final cutHeight = 140.0;      // фиксированная высота (удобно для штрих-кодов)
          final left = (w - cutWidth) / 2;
          final top  = h * 0.32;        // смещение сверху (~1/3 экрана)
          final cutout = Rect.fromLTWH(left, top, cutWidth, cutHeight);

          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                scanWindow: cutout,   // <<< распознаём ТОЛЬКО внутри этого окна
                fit: BoxFit.cover,
                // По желанию можно ограничить форматы, чтобы ускорить:
                // formats: const [
                //   BarcodeFormat.code128, BarcodeFormat.ean13,
                //   BarcodeFormat.ean8,   BarcodeFormat.upcA,
                //   BarcodeFormat.upcE,
                // ],
              ),
              _ScannerOverlay(cutOutRect: cutout),
            ],
          );
        },
      ),
    );
  }
}

/// Полупрозрачная маска + белая рамка с закруглёнными углами
class _ScannerOverlay extends StatelessWidget {
  final Rect cutOutRect;
  const _ScannerOverlay({required this.cutOutRect});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _OverlayPainter(cutOutRect),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect r;
  _OverlayPainter(this.r);

  @override
  void paint(Canvas c, Size size) {
    // затемняем всё…
    final bg = Paint()..color = Colors.black.withOpacity(0.55);
    final full = Path()..addRect(Offset.zero & size);

    // …кроме выреза (скруглённый прямоугольник)
    final cut = Path()
      ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)));
    final mask = Path.combine(PathOperation.difference, full, cut);
    c.drawPath(mask, bg);

    // белая рамка
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)), border);

    // уголки-подсказки (короткие засечки)
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    const len = 18.0;
    // левый верх
    c.drawLine(r.topLeft, r.topLeft + const Offset(len, 0), corner);
    c.drawLine(r.topLeft, r.topLeft + const Offset(0, len), corner);
    // правый верх
    c.drawLine(r.topRight, r.topRight + const Offset(-len, 0), corner);
    c.drawLine(r.topRight, r.topRight + const Offset(0, len), corner);
    // левый низ
    c.drawLine(r.bottomLeft, r.bottomLeft + const Offset(len, 0), corner);
    c.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -len), corner);
    // правый низ
    c.drawLine(r.bottomRight, r.bottomRight + const Offset(-len, 0), corner);
    c.drawLine(r.bottomRight, r.bottomRight + const Offset(0, -len), corner);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => old.r != r;
}
