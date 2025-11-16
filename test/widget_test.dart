import 'package:flutter_test/flutter_test.dart';
import 'package:lottogenerator_v4/main.dart';

void main() {
  testWidgets('App startet mit Titel Lottogenerator v4', (WidgetTester tester) async {
    await tester.pumpWidget(const LottoGeneratorApp());

    expect(find.text('Lottogenerator v4'), findsOneWidget);
  });
}
