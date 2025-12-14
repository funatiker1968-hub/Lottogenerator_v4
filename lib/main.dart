import 'package:flutter/material.dart';
import 'app_flow.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lottogenerator V4',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AppFlow(),
      debugShowCheckedModeBanner: false,
    );
  }
}
