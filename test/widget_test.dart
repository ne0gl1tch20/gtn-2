import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/game_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/design/expressive_widgets.dart';
import 'package:gtn_2/home/game_dashboard_page.dart';
import 'package:gtn_2/settings/game_settings.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Widget buildDashboard({GameSettings? settings, VoidCallback? onGuess}) =>
    M3EMaterialApp(
      data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
      fontFamily: 'Manrope',
      autoTheming: false,
      initialTheme: Brightness.light,
      home: GameDashboardPage(
        game: const GameState(secret: 42, attempts: 0, isComplete: false),
        progression: ProgressionState.initial,
        settings: settings ?? GameSettings.initial,
        activeSlot: 1,
        loading: false,
        message: 'Make your move.',
        controller: TextEditingController(),
        onGuess: onGuess ?? () {},
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
        onMusic: () {},
        onLuckyStake: () {},
        onSystems: () {},
        showDeveloperSettings: true,
      ),
    );

void main() {
  testWidgets(
    'guess controls show labels and submit action',
    (WidgetTester tester) async {
      var submitted = 0;
      await tester.pumpWidget(buildDashboard(onGuess: () => submitted++));

      expect(find.text('->'), findsOneWidget);
      expect(find.text('LOW END'), findsOneWidget);
      expect(find.text('MIDPOINT'), findsOneWidget);
      expect(find.text('HIGH END'), findsOneWidget);
      expect(find.text('CLEAR'), findsOneWidget);

      await tester.tap(find.text('->'));
      await tester.pump();
      expect(submitted, 1);

      await tester.tap(find.text('MIDPOINT'));
      await tester.pump();
      final field = tester.widget<GtnExpressiveTextField>(
        find.byKey(const Key('guess-input')),
      );
      expect(field.controller!.text, '50');
    },
  );

  testWidgets('shows the HTML-facing dashboard and quick-pick controls', (
    WidgetTester tester,
  ) async {
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

    TextEditingController guessController() => tester
        .widget<GtnExpressiveTextField>(find.byKey(const Key('guess-input')))
        .controller!;

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

  testWidgets('More follows the saved Menu Studio order and includes tools', (
    WidgetTester tester,
  ) async {
    final settings = GameSettings.initial.copyWith(
      moreScreenOrder: const ['music', 'settings', 'save_slots'],
      moreScreenButtonColors: const {'music': '#FF5722'},
    );
    await tester.pumpWidget(buildDashboard(settings: settings));
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('More Menu'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Save Slots'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Music')).dy,
      lessThan(tester.getTopLeft(find.text('Settings')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Settings')).dy,
      lessThan(tester.getTopLeft(find.text('Save Slots')).dy),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.library_music_rounded &&
            widget.color == const Color(0xFFFF5722),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Lucky Stake'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Lucky Stake'), findsOneWidget);
    expect(find.text('Lua hub'), findsNothing);
    expect(find.text('Live events'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Dev Settings'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Dev Settings'), findsOneWidget);
  });
}
