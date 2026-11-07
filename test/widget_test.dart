import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/main.dart';

void main() {
  testWidgets('shows the GTN 1-inspired game dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GtnApp());
    expect(find.text('Game Center'), findsOneWidget);
    expect(find.text('YOUR WALLET'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('MAKE YOUR GUESS'), 300);
    expect(find.text('MAKE YOUR GUESS'), findsOneWidget);
    expect(find.text('GUESS'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('YOUR JOURNEY'), 300);
    expect(find.text('YOUR JOURNEY'), findsOneWidget);
  });
}
