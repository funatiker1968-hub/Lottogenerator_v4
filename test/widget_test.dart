import 'package:flutter_test/flutter_test.dart';

import 'package:lottogenerator_v4/main.dart';

void main() {
  testWidgets('App startet mit HomeScreen und Titel', (WidgetTester tester) async {
    await tester.pumpWidget(const LottoGeneratorApp());

    expect(find.text('Lottogenerator v4'), findsOneWidget);
    expect(find.text('Lotto 6aus49'), findsOneWidget);
    expect(find.text('Eurojackpot'), findsOneWidget);
  });
}
