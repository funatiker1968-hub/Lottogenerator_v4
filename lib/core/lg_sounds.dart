import 'package:audioplayers/audioplayers.dart';

/// Zentrale Sound-Helfer für Lotto-Animationen.
/// Nutzt die vier WAV-Dateien aus assets/sounds/.
class LGSounds {
  static Future<void> _playAsset(String path) async {
    final player = AudioPlayer();
    await player.play(AssetSource(path));
  }

  /// Sound für Start der Superzahl-Kugel (schnelles Drehen / Glücksrad).
  static Future<void> playSuperzahlSpinStart() async {
    await _playAsset('assets/sounds/spin.wav');
  }

  /// Sound für Ende / Auslaufen der Superzahl-Kugel.
  static Future<void> playSuperzahlSpinEnd() async {
    await _playAsset('assets/sounds/slow.wav');
  }

  /// Sound wenn die Snake-Animation für die 6 Hauptzahlen startet.
  static Future<void> playSnakeStartSound() async {
    await _playAsset('assets/sounds/spin.wav');
  }

  /// Sound beim „Fressen“ einer generierten Zahl.
  static Future<void> playSnakeEatSound() async {
    await _playAsset('assets/sounds/eat.wav');
  }

  /// Sound wenn die Snake-Animation fertig ist / das Feld verlässt.
  static Future<void> playSnakeEndSound() async {
    await _playAsset('assets/sounds/exit.wav');
  }
}
