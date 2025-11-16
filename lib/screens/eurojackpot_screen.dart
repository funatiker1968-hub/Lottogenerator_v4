import 'package:flutter/material.dart';

/// Platzhalter für den Eurojackpot Screen.
/// Version 2025-11-16 16:12
class EurojackpotScreen extends StatelessWidget {
  const EurojackpotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eurojackpot"),
      ),
      body: const Center(
        child: Text(
          "Eurojackpot folgt in Kürze...",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
