import 'package:audioplayers/audioplayers.dart';

/// ---------------------------------------------------------------------------
///  CORE SOUNDS – zentraler Sound-Manager für Lotto 6aus49
/// ---------------------------------------------------------------------------
/// Unterstützt:
/// - play("datei.mp3")
/// - stop()
/// - mute
/// - preload aller Sounds
///
/// Vorhandene Dateien (vom Nutzer bestätigt):
///   spin_fast.mp3
///   spin_slow.mp3
///   snake_exit.mp3            → Stop-Sound für Superzahl
///   spinner-sound-36693.mp3   → Lotto 1–49 Durchlauf
/// ---------------------------------------------------------------------------

class LGSounds {
  static final AudioPlayer _player = AudioPlayer();
  static bool mute = false;

  /// Einmalige Vorladung aller relevanten Sounds
  static Future<void> preload() async {
    final cache = AudioCache(prefix: 'assets/sounds/');

    await cache.load('spin_fast.mp3');
    await cache.load('spin_slow.mp3');
    await cache.load('snake_exit.mp3');
    await cache.load('spinner-sound-36693.mp3');
  }

  /// Beliebigen Sound abspielen
  static Future<void> play(String fileName) async {
    if (mute) return;
    await _player.stop();
    await _player.play(AssetSource('sounds/$fileName'));
  }

  /// Lotto-Durchlauf: kurzer Klicksound pro Highlight
  static Future<void> playTick() async {
    if (mute) return;
    // kein Stop vorher → Tick darf schnell hintereinander kommen
    await _player.play(
      AssetSource('sounds/spinner-sound-36693.mp3'),
      volume: 1.0,
    );
  }

  /// Stoppt laufenden Sound
  static Future<void> stop() async {
    await _player.stop();
  }
}
