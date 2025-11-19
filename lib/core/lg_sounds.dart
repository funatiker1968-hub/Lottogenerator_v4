import 'package:audioplayers/audioplayers.dart';

/// Zentrale Soundklasse für Lotto6aus49
/// Die Datei wird automatisch geladen, wenn sie verwendet wird.
/// Alle Methoden sind statisch nutzbar.

class LGSounds {
  static final AudioPlayer _player = AudioPlayer();

  /// Superzahl – Start spin sound
  static Future<void> playSpin() async {
    await _play('assets/sounds/spin.wav');
  }

  /// Superzahl – slowdown / Endphase
  static Future<void> playSlow() async {
    await _play('assets/sounds/slow.wav');
  }

  /// Snake: frisst neue Zahl
  static Future<void> playEat() async {
    await _play('assets/sounds/eat.wav');
  }

  /// Snake-Ende
  static Future<void> playExit() async {
    await _play('assets/sounds/exit.wav');
  }

  /// interner Loader
  static Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset.replaceFirst('assets/', '')));
    } catch (e) {
      // Keine Crashes – einfach ignorieren
    }
  }
}
