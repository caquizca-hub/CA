import 'package:flutter_test/flutter_test.dart';
import 'package:ca/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CAQuizApp());

    // Verify that the app starts and shows the title.
    expect(find.text('Select Your Level'), findsOneWidget);
  });
}
