import 'package:flutter/material.dart';

class StatistikButton extends StatelessWidget {
  const StatistikButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bar_chart),
      tooltip: 'Statistik',
      onPressed: () {
        Navigator.of(context).pushNamed('/statistik');
      },
    );
  }
}
