import 'package:flutter/material.dart';
import 'historie_page.dart';

void main() {
  runApp(const LottoHistorieApp());
}

class LottoHistorieApp extends StatelessWidget {
  const LottoHistorieApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lotto Generator V4 mit Historie',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HistoriePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
