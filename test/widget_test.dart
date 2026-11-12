import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/game_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/design/expressive_widgets.dart';
import 'package:gtn_2/home/game_dashboard_page.dart';
import 'package:gtn_2/legacy/legacy_systems_page.dart';
import 'package:gtn_2/settings/game_settings.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Widget buildDashboard({
  GameSettings? settings,
  VoidCallback? onGuess,
  GlobalKey<NavigatorState>? shellNavigatorKey,
  ValueChanged<LegacySystemsView>? onSystemsView,
}) {
  final navigatorKey = shellNavigatorKey ?? GlobalKey<NavigatorState>();
  return M3EMaterialApp(
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
      shellNavigatorKey: navigatorKey,
      selectedIndex: 2,
      onPrimarySelected: (_) {},
      onSystemsView: onSystemsView ?? (_) {},
      onLegacySection: (_) {},
    ),
  );
}

void main() {
  testWidgets(
    'guess controls expose GTN1 accessibility labels and submit action',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      var submitted = 0;
      try {
        await tester.pumpWidget(buildDashboard(onGuess: () => submitted++));
        await tester.ensureVisible(find.byKey(const Key('guess-input')));
        await tester.pumpAndSettle();

        Finder semanticsWithLabel(String label) => find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == label,
          description: 'Semantics(label: $label)',
        );

        expect(semanticsWithLabel('Your guess'), findsOneWidget);
        expect(semanticsWithLabel('Guess'), findsOneWidget);
        expect(semanticsWithLabel('Use lower end of range'), findsOneWidget);
        expect(semanticsWithLabel('Use midpoint of range'), findsOneWidget);
        expect(semanticsWithLabel('Use upper end of range'), findsOneWidget);
        expect(semanticsWithLabel('Clear guess input'), findsOneWidget);

        await tester.tap(find.text('->'));
        await tester.pump();
        expect(submitted, 1);

        await tester.tap(find.bySemanticsLabel('Use midpoint of range'));
        await tester.pump();
        final field = tester.widget<GtnExpressiveTextField>(
          find.byKey(const Key('guess-input')),
        );
        expect(field.controller!.text, '50');
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('shows the HTML-facing dashboard and quick-pick controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildDashboard());
    expect(find.text('Guess The Number'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Beyond the Numbers'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    for (final label in [
      'YOUR GUESS',
      'QUICK PICK',
      'AUTOMATION LAB',
      'YOUR WALLET',
      'Daily Momentum',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        180,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.text('Guessing Bots'),
      180,
      scrollable: scrollable,
    );
    expect(find.text('NO BOTS YET'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('LOW END'),
      180,
      scrollable: scrollable,
    );
    TextEditingController guessController() => tester
        .widget<GtnExpressiveTextField>(find.byKey(const Key('guess-input')))
        .controller!;

    await tester.tap(find.text('LOW END'));
    await tester.pump();
    expect(guessController().text, '1');

    await tester.tap(find.text('MIDPOINT'));
    await tester.pump();
    expect(guessController().text, '50');

    await tester.tap(find.text('HIGH END'));
    await tester.pump();
    expect(guessController().text, '100');

    await tester.tap(find.text('CLEAR'));
    await tester.pump();
    expect(guessController().text, isEmpty);
  });

  testWidgets('More detail pages keep the shell and Back returns to More', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDashboard(
        onSystemsView: (view) {
          final shellNavigator = tester.state<NavigatorState>(
            find.descendant(
              of: find.byType(GameDashboardPage),
              matching: find.byType(Navigator),
            ),
          );
          shellNavigator.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(view.name)),
                body: const Center(child: Text('Feature detail')),
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    expect(find.text('More Menu'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Traits'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Traits'));
    await tester.pumpAndSettle();

    expect(find.text('Feature detail'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('More Menu'), findsOneWidget);
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
