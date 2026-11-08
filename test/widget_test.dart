import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/game_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/home/game_dashboard_page.dart';

Widget buildDashboard() => MaterialApp(
      home: GameDashboardPage(
        game: const GameState(secret: 42, attempts: 0, isComplete: false),
        progression: ProgressionState.initial,
        activeSlot: 1,
        loading: false,
        message: 'Make your move.',
        controller: TextEditingController(),
        onGuess: () {},
        onNewGame: () {},
        onUpgradeShop: () {},
        onPrestige: () {},
        onArcade: () {},
        onNebulaShop: () {},
        onWorldMap: () {},
        onSaveSlots: () {},
        onSettings: () {},
        onDeveloperSettings: () {},
        onLegacyPages: () {},
        showDeveloperSettings: true,
      ),
    );

void main() {
  testWidgets('shows the HTML-facing dashboard and quick-pick controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildDashboard());
    expect(find.text('Guess The Number'), findsOneWidget);
    expect(find.text('YOUR WALLET'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Beyond the Numbers'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('YOUR GUESS'), findsOneWidget);
    expect(find.text('->'), findsOneWidget);
    expect(find.text('QUICK PICK'), findsOneWidget);
    expect(find.text('LOW END'), findsOneWidget);
    expect(find.text('MIDPOINT'), findsOneWidget);
    expect(find.text('HIGH END'), findsOneWidget);
    expect(find.text('CLEAR'), findsOneWidget);


  });

  testWidgets('More opens its own destination with save and dev tools',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildDashboard());
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('More Menu'), findsOneWidget);
    expect(find.text('Save Slots'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Dev Settings'), findsOneWidget);
  });
}
