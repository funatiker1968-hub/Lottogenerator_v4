import 'package:flutter/material.dart';
import 'screens/disclaimer_screen.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const LottoGeneratorApp());
}

class LottoGeneratorApp extends StatefulWidget {
  const LottoGeneratorApp({super.key});

  @override
  State<LottoGeneratorApp> createState() => _LottoGeneratorAppState();
}

class _LottoGeneratorAppState extends State<LottoGeneratorApp> {
  bool _accepted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      final accepted = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DisclaimerScreen(),
        ),
      );
      setState(() {
        _accepted = accepted == true;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (!_accepted) {
      SystemNavigator.pop();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            "Lottogenerator v4 – Startscreen\n(Hier kommt später alles rein)",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
