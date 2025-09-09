import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

final _player = AudioPlayer();

Future<void> handleScan(String code) async {
  // Проигрываем beep.mp3 из assets
  _player.play(AssetSource('sounds/beep.mp3'));

  final Uri uri = Uri.parse('http://192.168.0.127:5002/edit/$code');
  if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
    // ignore: avoid_print
    print('Could not launch $uri');
  }
}
