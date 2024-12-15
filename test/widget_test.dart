import 'package:flutter_test/flutter_test.dart';
import 'package:chromaniac/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChromaniacApp());
    expect(find.text('Chromaniac - Color Palette Creator'), findsOneWidget);
  });
}
