import 'package:flutter/material.dart';
import 'import_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lottogenerator v4')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Import testen'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            );
          },
        ),
      ),
    );
  }
}
