import 'package:flutter/material.dart';

void main() {
  runApp(const LottoGeneratorApp());
}

class LottoGeneratorApp extends StatelessWidget {
  const LottoGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lottogenerator v4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lottogenerator v4'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Wähle dein System:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const Lotto6aus49Screen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Lotto 6aus49',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EurojackpotScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Eurojackpot',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'v4 – Basisnavigation, Logik folgt noch.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class Lotto6aus49Screen extends StatelessWidget {
  const Lotto6aus49Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto 6aus49'),
      ),
      body: const Center(
        child: Text(
          'Lotto 6aus49 UI folgt…',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class EurojackpotScreen extends StatelessWidget {
  const EurojackpotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eurojackpot'),
      ),
      body: const Center(
        child: Text(
          'Eurojackpot UI folgt…',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
