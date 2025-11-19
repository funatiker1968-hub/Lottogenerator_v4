import 'package:audioplayers/audioplayers.dart';

/// Globale Soundklasse für Lotto-Generator
class LGSounds {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play(String file) async {
    try {
      await _player.stop();
      await _player.play(
        AssetSource('sounds/$file'),
        volume: 1.0,
      );
    } catch (e) {
      // keine Errors anzeigen
    }
  }

  static Future<void> spinStart() async => play('spin.wav');
  static Future<void> spinEnd() async => play('slow.wav');
  static Future<void> snakeStart() async => play('spin.wav');
  static Future<void> snakeEat() async => play('eat.wav');
  static Future<void> snakeEnd() async => play('exit.wav');
}
