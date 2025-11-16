// widget_test.dart - Lottogenerator v4
// Version: 2025-11-16 15:47 (MEZ)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lottogenerator_v4/main.dart';

void main() {
  testWidgets('App startet und zeigt Titel', (WidgetTester tester) async {
    await tester.pumpWidget(const LottoApp());

    expect(find.text('Lottogenerator v4'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
