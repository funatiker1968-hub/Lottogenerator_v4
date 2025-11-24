import 'package:audioplayers/audioplayers.dart';

/// ---------------------------------------------------------------------------
///  SOUND-MODUL – LGSounds
/// ---------------------------------------------------------------------------

class LGSounds {
  static final AudioPlayer _spinFast = AudioPlayer();
  static final AudioPlayer _spinSlow = AudioPlayer();
  static final AudioPlayer _snakeEat = AudioPlayer();
  static final AudioPlayer _snakeOut = AudioPlayer();

  /// Sehr schneller Spin (Start)
  static Future<void> playSpinFast() async {
    try {
      await _spinFast.play(
        AssetSource('sounds/spin_fast.mp3'),
      );
    } catch (_) {}
  }

  /// Langsamer Spin (Stopp)
  static Future<void> playSpinSlow() async {
    try {
      await _spinSlow.play(
        AssetSource('sounds/spin_slow.mp3'),
      );
    } catch (_) {}
  }

  /// Snake isst Zahl
  static Future<void> playSnakeEat() async {
    try {
      await _snakeEat.play(
        AssetSource('sounds/snake_eat.mp3'),
      );
    } catch (_) {}
  }

  /// Snake verlässt das Spielfeld
  static Future<void> playSnakeOut() async {
    try {
      await _snakeOut.play(
        AssetSource('sounds/snake_out.mp3'),
      );
    } catch (_) {}
  }
}
