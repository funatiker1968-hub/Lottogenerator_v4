import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class StatistikButton extends StatelessWidget {
  final AudioPlayer audioPlayer;
  
  const StatistikButton({super.key, required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bar_chart),
      onPressed: () {
        audioPlayer.play(AssetSource('sounds/click.mp3'));
        Navigator.pushNamed(context, '/statistik');
      },
      tooltip: 'Statistiken',
    );
  }
}
