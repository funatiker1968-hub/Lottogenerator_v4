import 'package:audioplayers/audioplayers.dart';

class LGSounds {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSpinStart() async {
    await _player.play(AssetSource('sounds/spin.wav'));
  }

  static Future<void> playSpinEnd() async {
    await _player.play(AssetSource('sounds/slow.wav'));
  }

  static Future<void> playSnakeEat() async {
    await _player.play(AssetSource('sounds/eat.wav'));
  }

  static Future<void> playSnakeEnd() async {
    await _player.play(AssetSource('sounds/exit.wav'));
  }
}
