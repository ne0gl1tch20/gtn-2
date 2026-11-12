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

        expect(find.bySemanticsLabel('Your guess'), findsOneWidget);
        expect(find.bySemanticsLabel('Guess'), findsOneWidget);
        expect(find.bySemanticsLabel('Use lower end of range'), findsOneWidget);
        expect(find.bySemanticsLabel('Use midpoint of range'), findsOneWidget);
        expect(find.bySemanticsLabel('Use upper end of range'), findsOneWidget);
        expect(find.bySemanticsLabel('Clear guess input'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Guess'));
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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildDashboard());
    expect(find.text('Guess The Number'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Beyond the Numbers'), findsWidgets);
    expect(find.text('More'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('YOUR GUESS'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('YOUR GUESS'), findsOneWidget);
    expect(find.text('Guessing Bots'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Guessing Bots')).dy,
      lessThan(tester.getTopLeft(find.text('YOUR GUESS')).dy),
      reason: 'GTN1 places the automation arena before the guess panel.',
    );
    expect(find.text('QUICK PICK'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

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

    for (final label in [
      'MONEY',
      'AUTOMATION LAB',
      'Guessing Bots',
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
    expect(find.text('NO BOTS YET'), findsOneWidget);
  });

  testWidgets('More detail pages keep the shell and Back returns to More', (
    WidgetTester tester,
  ) async {
    final shellKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(buildDashboard(shellNavigatorKey: shellKey));

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('More Menu'), findsOneWidget);

    shellKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Traits')),
          body: const Center(child: Text('Feature detail')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feature detail'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('More Menu'), findsOneWidget);
  });

  testWidgets('default More menu keeps GTN1 destination names', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildDashboard());
    await tester.tap(find.text('More').first);
    await tester.pumpAndSettle();

    expect(find.text('More Menu'), findsOneWidget);
    for (final label in [
      'Rewards',
      'Journey',
      'Shop',
      'Home Base',
      'Relics',
      'Codex',
      'Changelog',
      'Background Music',
      'Settings',
      'Prestige',
      'Ultra',
      'Talents',
      'Traits',
      'Mutators',
      'Stats',
      'Lucky Stake',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Play dashboard sections stay full width on desktop', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildDashboard());

    for (final key in [
      'dashboard-hero-section',
      'dashboard-guess-section',
      'dashboard-stats-section',
      'dashboard-wallet-section',
    ]) {
      expect(
        tester.getSize(find.byKey(Key(key))).width,
        greaterThan(700),
        reason: '$key should follow GTN1 full-width Play flow on desktop.',
      );
    }
  });

  testWidgets('More hub switches to the GTN1 two-column layout above 520px', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildDashboard());
    await tester.tap(find.text('More').first);
    await tester.pumpAndSettle();

    final rewards = tester.getTopLeft(find.text('Rewards'));
    final journey = tester.getTopLeft(find.text('Journey'));
    expect(rewards.dx, lessThan(journey.dx));
    expect(rewards.dy, journey.dy);
  });

  testWidgets('More follows the saved Menu Studio order and includes tools', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = GameSettings.initial.copyWith(
      moreScreenOrder: const ['music', 'settings', 'save_slots'],
      moreScreenButtonColors: const {'music': '#FF5722'},
    );
    await tester.pumpWidget(buildDashboard(settings: settings));
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('More Menu'), findsOneWidget);
    expect(find.text('Background Music'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Save Slots'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Background Music')).dy,
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
