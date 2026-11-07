import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/main.dart';

void main() {
  testWidgets('shows the GTN 2 game screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GtnApp());
    expect(find.text('GuessTheNumber 2'), findsOneWidget);
    expect(find.text('Guess'), findsOneWidget);
  });
}
