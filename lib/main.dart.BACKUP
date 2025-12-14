import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/lotto_import_service.dart';
import 'services/eurojackpot_import_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-Importe (nur wenn DB leer)
  await LottoImportService().import6aus49FromAsset(
    status: (_) {},
  );

  await EurojackpotImportService.instance.importIfEmpty(
    status: (_) {},
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
