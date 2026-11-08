import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/main.dart';

void main() {
  testWidgets('shows the GTN 1-inspired game dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GtnApp());
    expect(find.text('Guess The Number'), findsOneWidget);
    expect(find.text('CURRENT RUN'), findsOneWidget);
    expect(find.text('Find your secret number'), findsOneWidget);
    expect(find.text('YOUR WALLET'), findsOneWidget);
  });
}
