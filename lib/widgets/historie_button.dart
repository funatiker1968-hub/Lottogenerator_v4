import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class HistorieButton extends StatelessWidget {
  final AudioPlayer audioPlayer;
  
  const HistorieButton({super.key, required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.history),
      onPressed: () {
        audioPlayer.play(AssetSource('sounds/click.mp3'));
        Navigator.pushNamed(context, '/historie');
      },
      tooltip: 'Historische Daten',
    );
  }
}
