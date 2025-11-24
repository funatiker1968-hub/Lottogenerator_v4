import 'package:audioplayers/audioplayers.dart';

/// Zentrales Sound-Modul für alle Screens.
/// Nutzt MP3-Dateien aus assets/sounds.
///
/// Unterstützt sowohl die neuen Methoden
///   - playSpinFast / playSpinSlow
///   - playSnakeEat / playSnakeOut
/// als auch alte Alias-Namen:
///   - playSpinStart / playSpinEnd
///   - playSnakeExit

class LGSounds {
  static final AudioPlayer _spinFast = AudioPlayer();
  static final AudioPlayer _spinSlow = AudioPlayer();
  static final AudioPlayer _snakeEat = AudioPlayer();
  static final AudioPlayer _snakeOut = AudioPlayer();

  static Future<void> _safePlay(AudioPlayer player, String asset) async {
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  /// Sehr schneller Spin (Startphase der Superzahl)
  static Future<void> playSpinFast() async {
    await _safePlay(_spinFast, 'sounds/spin_fast.mp3');
  }

  /// Langsamer Spin (Auslaufphase der Superzahl)
  static Future<void> playSpinSlow() async {
    await _safePlay(_spinSlow, 'sounds/spin_slow.mp3');
  }

  /// Snake isst eine Zahl
  static Future<void> playSnakeEat() async {
    await _safePlay(_snakeEat, 'sounds/snake_eat.mp3');
  }

  /// Snake verlässt das Spielfeld / läuft unten raus
  static Future<void> playSnakeOut() async {
    await _safePlay(_snakeOut, 'sounds/snake_out.mp3');
  }

  // --------------------------------------------------
  // Alte Alias-Namen (für ältere Screens/Code-Stände)
  // --------------------------------------------------

  static Future<void> playSpinStart() async => playSpinFast();

  static Future<void> playSpinEnd() async => playSpinSlow();

  static Future<void> playSnakeExit() async => playSnakeOut();
}
