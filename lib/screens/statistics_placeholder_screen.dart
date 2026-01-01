import 'package:flutter/material.dart';

class StatisticsPlaceholderScreen extends StatelessWidget {
  const StatisticsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      body: const Center(
        child: Text(
          'Statistik folgt nach Import-Neuaufbau',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
