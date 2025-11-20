import 'package:audioplayers/audioplayers.dart';

/// Zentraler Sound-Controller.
/// Nutzt neue audioplayers API (AudioPlayer + AssetSource)

class LGSounds {
  static final AudioPlayer _spinStart = AudioPlayer();
  static final AudioPlayer _spinEnd   = AudioPlayer();
  static final AudioPlayer _snakeEat  = AudioPlayer();
  static final AudioPlayer _snakeExit = AudioPlayer();
  static final AudioPlayer _snakeStart = AudioPlayer();

  static Future<void> playSpinStart() async {
    try {
      await _spinStart.play(
        AssetSource('sounds/spin.wav'),
        volume: 1.0,
      );
    } catch (_) {}
  }

  static Future<void> playSpinEnd() async {
    try {
      await _spinEnd.play(
        AssetSource('sounds/slow.wav'),
        volume: 1.0,
      );
    } catch (_) {}
  }

  static Future<void> playSnakeEat() async {
    try {
      await _snakeEat.play(
        AssetSource('sounds/eat.wav'),
        volume: 1.0,
      );
    } catch (_) {}
  }

  static Future<void> playSnakeStart() async {
    try {
      await _snakeStart.play(
        AssetSource('sounds/spin.wav'),
        volume: 1.0,
      );
    } catch (_) {}
  }

  static Future<void> playSnakeEnd() async {
    try {
      await _snakeExit.play(
        AssetSource('sounds/exit.wav'),
        volume: 1.0,
      );
    } catch (_) {}
  }
}
