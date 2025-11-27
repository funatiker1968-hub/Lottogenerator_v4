import 'package:audioplayers/audioplayers.dart';

/// ---------------------------------------------------------------------------
///  CORE SOUNDS – stabil, kompatibel mit audioplayers 5.x
/// ---------------------------------------------------------------------------
class LGSounds {
  static final AudioPlayer _player = AudioPlayer();
  static bool mute = false;

  /// Kann für spätere Vorladungen genutzt werden – derzeit nicht notwendig.
  static Future<void> preload() async {
    // no-op
  }

  /// Beliebigen Sound spielen
  static Future<void> play(String fileName) async {
    if (mute) return;
    await _player.stop();
    await _player.play(
      AssetSource('sounds/$fileName'),
    );
  }

  /// Lotto-Klicksound beim Durchlauf (1..49)
  static Future<void> playTick() async {
    if (mute) return;
    await _player.play(
      AssetSource('sounds/spinner-sound-36693.mp3'),
    );
  }

  /// Sound stoppen
  static Future<void> stop() async {
    await _player.stop();
  }
}
