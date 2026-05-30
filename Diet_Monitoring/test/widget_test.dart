import 'package:flutter_test/flutter_test.dart';
import 'package:vital_track/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VitalTrackApp());
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}