import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/disclaimer_screen.dart';

void main() {
  runApp(const LottoGeneratorApp());
}

class LottoGeneratorApp extends StatefulWidget {
  const LottoGeneratorApp({super.key});

  @override
  State<LottoGeneratorApp> createState() => _LottoGeneratorAppState();
}

class _LottoGeneratorAppState extends State<LottoGeneratorApp> {
  bool _acceptedDisclaimer = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lottogenerator V4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: _acceptedDisclaimer 
          ? const PlaceholderScreen() 
          : DisclaimerScreen(
              onAccept: () {
                setState(() {
                  _acceptedDisclaimer = true;
                });
              },
              onDecline: () {
                SystemNavigator.pop();
              },
            ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home (folgt)"),
      ),
      body: const Center(
        child: Text(
          "Der HomeScreen wird gleich erstellt...",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
