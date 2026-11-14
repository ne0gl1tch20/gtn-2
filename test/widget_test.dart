import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/game_engine.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/design/expressive_widgets.dart';
import 'package:gtn_2/home/game_dashboard_page.dart';
import 'package:gtn_2/legacy/legacy_pages.dart';
import 'package:gtn_2/legacy/legacy_systems_page.dart';
import 'package:gtn_2/profile/player_profile_page.dart';
import 'package:gtn_2/settings/game_settings.dart';
import 'package:gtn_2/settings/menu_studio_layout.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Widget buildDashboard({
  GameSettings? settings,
  bool loading = false,
  VoidCallback? onGuess,
  String? randomEventMessage,
  BigNumber? incomePerSecond,
  GlobalKey<NavigatorState>? shellNavigatorKey,
  ValueChanged<LegacySystemsView>? onSystemsView,
  ValueChanged<LegacySection>? onLegacySection,
  VoidCallback? onPlayerProfile,
  VoidCallback? onNebulaShop,
  ValueChanged<int>? onPrimarySelected,
}) {
  final navigatorKey = shellNavigatorKey ?? GlobalKey<NavigatorState>();
  final dashboardSettings = settings ?? GameSettings.initial;
  final menuLayout = MenuStudioLayout.fromSettings(dashboardSettings);
  return M3EMaterialApp(
    data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
    fontFamily: 'Manrope',
    autoTheming: false,
    initialTheme: Brightness.light,
    home: GameDashboardPage(
      game: const GameState(secret: 42, attempts: 0, isComplete: false),
      progression: ProgressionState.initial,
      settings: dashboardSettings,
      activeSlot: 1,
      loading: loading,
      message: 'Make your move.',
      randomEventMessage: randomEventMessage,
      incomePerSecond: incomePerSecond,
      controller: TextEditingController(),
      onGuess: onGuess ?? () {},
      onNewGame: () {},
      onUpgradeShop: () {},
      onPrestige: () {},
      onArcade: () {},
      onNebulaShop: onNebulaShop ?? () {},
      onWorldMap: () {},
      onSaveSlots: () {},
      onSettings: () {},
      onDeveloperSettings: () {},
      onLegacyPages: () {},
      onLiveOps: () {},
      onMusic: () {},
      onLuckyStake: () {},
      onSystems: () {},
      showDeveloperSettings: true,
      shellNavigatorKey: navigatorKey,
      selectedIndex: menuLayout.playIndex,
      onPrimarySelected: onPrimarySelected ?? (_) {},
      onSystemsView: onSystemsView ?? (_) {},
      onLegacySection: onLegacySection ?? (_) {},
      onPlayerProfile: onPlayerProfile,
    ),
  );
}

void main() {
  testWidgets('save restoration shows a blocking loading state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildDashboard(loading: true));

    expect(find.text('Loading your game'), findsOneWidget);
    expect(
      find.text('Restoring save slot 1 and preparing your next round.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dashboard-loading-barrier')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Money displays the live income-per-second rate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDashboard(incomePerSecond: BigNumber.fromInt(24)),
    );
    expect(find.text('+ 24 /s'), findsOneWidget);
    expect(find.text('0 earned'), findsOneWidget);
  });

  testWidgets('Menu Studio moves a pinned tab into the More menu', (
    WidgetTester tester,
  ) async {
    final defaults = MenuStudioLayout.defaults();
    final areas = Map<String, String>.of(defaults.areas)..['worlds'] = 'more';
    final navOrder = List<String>.of(defaults.navOrder)..remove('worlds');
    final moreOrder = [...defaults.moreOrder, 'worlds'];
    final layout = defaults.copyWith(
      areas: areas,
      navOrder: navOrder,
      moreOrder: moreOrder,
    );
    final settings = GameSettings.initial.copyWith(
      moreScreenOrder: layout.settingsMoreOrder,
      moreScreenButtonColors: layout.settingsColors,
      webMenuStudioLayout: layout.encode(),
    );

    await tester.pumpWidget(buildDashboard(settings: settings));
    await tester.tap(find.text('More').first);
    await tester.pumpAndSettle();

    expect(find.text('Beyond the Numbers'), findsOneWidget);
  });

  testWidgets('Menu Studio moves a More destination into navigation', (
    WidgetTester tester,
  ) async {
    LegacySection? openedSection;
    final defaults = MenuStudioLayout.defaults();
    final areas = Map<String, String>.of(defaults.areas)..['rewards'] = 'nav';
    final navOrder = [...defaults.navOrder, 'rewards'];
    final moreOrder = List<String>.of(defaults.moreOrder)..remove('rewards');
    final layout = defaults.copyWith(
      areas: areas,
      navOrder: navOrder,
      moreOrder: moreOrder,
    );
    final settings = GameSettings.initial.copyWith(
      moreScreenOrder: layout.settingsMoreOrder,
      moreScreenButtonColors: layout.settingsColors,
      webMenuStudioLayout: layout.encode(),
    );

    await tester.pumpWidget(
      buildDashboard(
        settings: settings,
        onLegacySection: (section) => openedSection = section,
      ),
    );
    expect(find.text('Rewards'), findsOneWidget);
    await tester.tap(find.text('Rewards'));
    await tester.pumpAndSettle();
    expect(openedSection, LegacySection.rewards);
  });

  testWidgets('More menu has one Dev Settings item and opens Nebula Shop', (
    WidgetTester tester,
  ) async {
    var openedNebulaShop = 0;
    await tester.pumpWidget(
      buildDashboard(onNebulaShop: () => openedNebulaShop++),
    );

    await tester.tap(find.text('More').first);
    await tester.pumpAndSettle();

    expect(find.text('Dev Settings'), findsOneWidget);
    await tester.tap(find.text('Shop').first);
    await tester.pumpAndSettle();
    expect(openedNebulaShop, 1);
  });

  testWidgets('Daily Momentum opens the GTN1 Rewards destination', (
    WidgetTester tester,
  ) async {
    LegacySection? openedSection;
    await tester.pumpWidget(
      buildDashboard(onLegacySection: (section) => openedSection = section),
    );
    await tester.scrollUntilVisible(
      find.text('Daily Momentum'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Momentum'));
    expect(openedSection, LegacySection.rewards);
  });

  testWidgets('shows the temporary random-event dashboard banner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDashboard(randomEventMessage: 'Cash Burst · bonus Money added'),
    );
    expect(find.text('RANDOM EVENT'), findsOneWidget);
    expect(find.text('Cash Burst · bonus Money added'), findsOneWidget);
  });

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

  testWidgets('guess input receives focus and accepts typed numbers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildDashboard());
    final input = find.byKey(const Key('guess-input'));
    await tester.ensureVisible(input);
    await tester.pumpAndSettle();
    await tester.tap(input);
    await tester.enterText(input, '73');
    await tester.pump();

    final field = tester.widget<GtnExpressiveTextField>(input);
    expect(field.controller!.text, '73');
    expect(tester.testTextInput.isVisible, isTrue);
  });

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
    expect(find.text('More').first, findsOneWidget);

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

  testWidgets('closing More restores Play as the selected destination', (
    WidgetTester tester,
  ) async {
    var selectedIndex = 2;
    final shellKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      buildDashboard(
        shellNavigatorKey: shellKey,
        onPrimarySelected: (index) => selectedIndex = index,
      ),
    );

    await tester.tap(find.text('More').first);
    await tester.pumpAndSettle();
    expect(selectedIndex, 4);
    expect(find.text('More'), findsWidgets);
    expect(find.text('Player profile'), findsOneWidget);
    expect(find.text('Save Slots'), findsOneWidget);
    expect(find.text('Background Music'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Nebula Shop'), findsNothing);

    shellKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(selectedIndex, 2);
    expect(find.text('Guess The Number'), findsOneWidget);
  });

  testWidgets('More detail pages keep the shell and Back returns to More', (
    WidgetTester tester,
  ) async {
    final shellKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(buildDashboard(shellNavigatorKey: shellKey));

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('More').first, findsOneWidget);

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
    expect(find.text('More').first, findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('More').first, findsOneWidget);
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

    expect(find.text('More').first, findsOneWidget);
    expect(find.byKey(const Key('more-global-topbar')), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'More'), findsNothing);
    expect(find.text('OFFLINE'), findsWidgets);
    for (final label in [
      'Player profile',
      'Rewards',
      'Journey',
      'Shop',
      'Home Base',
      'Relics',
      'Codex',
      'Changelog',
      'About',
      'Save Slots',
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
    const sourceOrder = [
      'Rewards',
      'Journey',
      'Shop',
      'Home Base',
      'Relics',
      'Codex',
      'Changelog',
      'About',
      'Save Slots',
      'Background Music',
      'Settings',
      'Prestige',
      'Ultra',
      'Talents',
      'Traits',
      'Mutators',
      'Stats',
      'Lucky Stake',
    ];
    for (var index = 0; index < sourceOrder.length - 1; index++) {
      expect(
        tester.getTopLeft(find.text(sourceOrder[index])).dy,
        lessThan(tester.getTopLeft(find.text(sourceOrder[index + 1])).dy),
        reason:
            '${sourceOrder[index]} should precede ${sourceOrder[index + 1]}',
      );
    }
  });

  testWidgets('Player Profile validates username before saving', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerProfilePage(
          initialProfile: const PlayerProfile(),
          store: PlayerProfileStore(),
          onSaved: (_) {},
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Save profile'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Username must be 2–20 characters.'), findsOneWidget);
  });

  testWidgets('More opens the Player Profile destination callback', (
    WidgetTester tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(buildDashboard(onPlayerProfile: () => opened++));
    await tester.tap(find.text('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player profile'));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('Play dashboard sections stay full width on desktop', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
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

  testWidgets('quick actions stack on mobile and split on desktop', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildDashboard());
    var beyond = tester.getTopLeft(
      find.byKey(const Key('dashboard-action-beyond')),
    );
    var daily = tester.getTopLeft(
      find.byKey(const Key('dashboard-action-daily')),
    );
    expect(beyond.dy, lessThan(daily.dy));
    expect(beyond.dx, daily.dx);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();
    beyond = tester.getTopLeft(
      find.byKey(const Key('dashboard-action-beyond')),
    );
    daily = tester.getTopLeft(find.byKey(const Key('dashboard-action-daily')));
    expect(beyond.dy, daily.dy);
    expect(beyond.dx, lessThan(daily.dx));
  });

  testWidgets('desktop Bot Arena uses the GTN1 half-column width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildDashboard());

    final heroWidth = tester
        .getSize(find.byKey(const Key('dashboard-hero-section')))
        .width;
    final botArenaWidth = tester
        .getSize(find.byKey(const Key('dashboard-bot-arena-section')))
        .width;
    expect(botArenaWidth, lessThan(heroWidth));
    expect(botArenaWidth, greaterThan(500));
  });

  testWidgets('More profile stays full width and links use GTN1 breakpoint', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildDashboard());
    await tester.tap(find.text('More').first);
    await tester.pumpAndSettle();

    final profileWidth = tester
        .getSize(find.byKey(const Key('more-profile-card')))
        .width;
    final rewards = tester.getTopLeft(find.text('Rewards'));
    final journey = tester.getTopLeft(find.text('Journey'));
    final rewardsWidth = tester
        .getSize(find.byKey(const Key('more-card-rewards')))
        .width;
    expect(profileWidth, greaterThan(rewardsWidth));
    expect(rewards.dy, journey.dy);
    expect(rewards.dx, lessThan(journey.dx));
  });

  testWidgets('More follows the saved Menu Studio order and includes tools', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = GameSettings.initial.copyWith(
      moreScreenOrder: const ['settings', 'music'],
      moreScreenButtonColors: const {'music': '#FF5722'},
    );
    await tester.pumpWidget(buildDashboard(settings: settings));
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('More').first, findsOneWidget);
    expect(find.text('Background Music'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Save Slots'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Settings')).dy,
      lessThan(tester.getTopLeft(find.text('Save Slots')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Save Slots')).dy,
      lessThan(tester.getTopLeft(find.text('Background Music')).dy),
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
