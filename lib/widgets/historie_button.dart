import 'package:flutter/material.dart';

class HistorieButton extends StatelessWidget {
  const HistorieButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.history),
      tooltip: 'Historie ansehen',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historie-Funktion kommt später.')),
        );
      },
    );
  }
}
