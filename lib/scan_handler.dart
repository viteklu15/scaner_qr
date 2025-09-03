import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> handleScan(String code) async {
  await SystemSound.play(SystemSoundType.alert);
  final Uri uri = Uri.parse('https://ya.ru/$code');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // ignore: avoid_print
    print('Could not launch $uri');
  }
}

