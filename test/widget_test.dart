import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/game_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/home/game_dashboard_page.dart';

Widget buildDashboard() => M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.light,
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
    // The dashboard uses a lazy ListView, so scroll to the wallet before asserting it.
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('YOUR WALLET'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Beyond the Numbers'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Daily Momentum'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Daily Momentum'), findsOneWidget);

    // Return to the top before checking the Automation Lab above the wallet.
    await tester.drag(find.byType(ListView).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('AUTOMATION LAB'), findsOneWidget);
    expect(find.text('Guessing Bots'), findsOneWidget);
    expect(find.text('NO BOTS YET'), findsOneWidget);
    expect(find.text('YOUR GUESS'), findsOneWidget);
    expect(find.text('->'), findsOneWidget);
    expect(find.text('QUICK PICK'), findsOneWidget);
    expect(find.text('LOW END'), findsOneWidget);
    expect(find.text('MIDPOINT'), findsOneWidget);
    expect(find.text('HIGH END'), findsOneWidget);
    expect(find.text('CLEAR'), findsOneWidget);

    TextEditingController guessController() =>
        tester.widget<TextField>(find.byKey(const Key('guess-input'))).controller!;

    await tester.ensureVisible(find.text('LOW END'));
    await tester.tap(find.text('LOW END'));
    await tester.pump();
    expect(guessController().text, '1');

    await tester.ensureVisible(find.text('MIDPOINT'));
    await tester.tap(find.text('MIDPOINT'));
    await tester.pump();
    expect(guessController().text, '50');

    await tester.ensureVisible(find.text('HIGH END'));
    await tester.tap(find.text('HIGH END'));
    await tester.pump();
    expect(guessController().text, '100');

    await tester.ensureVisible(find.text('CLEAR'));
    await tester.tap(find.text('CLEAR'));
    await tester.pump();
    expect(guessController().text, isEmpty);
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
