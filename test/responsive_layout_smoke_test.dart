import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/game_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/home/game_dashboard_page.dart';
import 'package:gtn_2/profile/player_profile_page.dart';
import 'package:gtn_2/progression/progression_hub_page.dart';
import 'package:gtn_2/saves/save_slots_page.dart';
import 'package:gtn_2/settings/game_settings.dart';
import 'package:gtn_2/settings/menu_studio_layout.dart';
import 'package:gtn_2/settings/menu_studio_page.dart';
import 'package:gtn_2/settings/settings_page.dart';
import 'package:gtn_2/shop/upgrade_catalog.dart';
import 'package:gtn_2/shop/upgrade_shop_page.dart';
import 'package:gtn_2/worlds/world_map_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

const _viewports = <({int width, int height})>[
  (width: 320, height: 640),
  (width: 360, height: 720),
  (width: 390, height: 844),
  (width: 430, height: 900),
  (width: 600, height: 900),
  (width: 719, height: 900),
  (width: 720, height: 900),
  (width: 1024, height: 768),
  (width: 1100, height: 800),
  (width: 1280, height: 800),
];

Widget _app(Widget home) => M3EMaterialApp(
  data: M3EThemeData.dark(seedColor: const Color(0xFF7C5CFC)),
  fontFamily: 'Manrope',
  autoTheming: false,
  initialTheme: Brightness.dark,
  themeAnimationDuration: Duration.zero,
  home: home,
);

Widget _dashboard(List<TextEditingController> controllers) {
  final settings = GameSettings.initial;
  final layout = MenuStudioLayout.fromSettings(settings);
  final controller = TextEditingController();
  controllers.add(controller);
  final navigatorKey = GlobalKey<NavigatorState>();
  return GameDashboardPage(
    game: const GameState(secret: 42, attempts: 0, isComplete: false),
    progression: ProgressionState.initial,
    settings: settings,
    activeSlot: 1,
    loading: false,
    message: 'Make your move.',
    controller: controller,
    onGuess: () {},
    onNewGame: () {},
    onUpgradeShop: () {},
    onPrestige: () {},
    onUltra: () {},
    onArcade: () {},
    onNebulaShop: () {},
    onWorldMap: () {},
    onLiveOps: () {},
    onLegacyPages: () {},
    onSaveSlots: () {},
    onSettings: () {},
    onDeveloperSettings: () {},
    onMusic: () {},
    onLuckyStake: () {},
    onSystems: () {},
    showDeveloperSettings: true,
    shellNavigatorKey: navigatorKey,
    selectedIndex: layout.playIndex,
    onPrimarySelected: (_) {},
    onSystemsView: (_) {},
    onLegacySection: (_) {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(UpgradeCatalog.load);

  testWidgets(
    'core player screens stay free of layout exceptions across phone, tablet and desktop widths',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controllers = <TextEditingController>[];
      addTearDown(() {
        for (final controller in controllers) {
          controller.dispose();
        }
      });

      final progression = ProgressionState.initial;
      final screens = <({String name, Widget Function() build})>[
        (name: 'Play dashboard', build: () => _dashboard(controllers)),
        (
          name: 'Settings',
          build: () => SettingsPage(
            settings: GameSettings.initial,
            onChanged: (_) async {},
          ),
        ),
        (
          name: 'Menu Studio',
          build: () => MenuStudioPage(
            settings: GameSettings.initial,
            onChanged: (_) async {},
          ),
        ),
        (
          name: 'Player Profile',
          build: () => PlayerProfilePage(
            initialProfile: const PlayerProfile(
              username: 'Player',
              profileId: 'responsive-smoke-profile',
              setupComplete: true,
            ),
            store: PlayerProfileStore(),
            onSaved: (_) {},
          ),
        ),
        (
          name: 'Save Slots',
          build: () => SaveSlotsPage(
            activeSlot: 1,
            settings: GameSettings.initial,
            onSelect: (_) async {},
            previewLoader: (_) async => null,
          ),
        ),
        (
          name: 'Upgrade Shop',
          build: () => UpgradeShopPage(
            progression: progression,
            onPurchase: (definition, {required levels}) async => progression,
          ),
        ),
        (
          name: 'World Map',
          build: () => WorldMapPage(
            progression: progression,
            onAction: (_, __) async => progression,
          ),
        ),
        (
          name: 'Progression Hub',
          build: () => ProgressionHubPage(
            progression: progression,
            onPrestige: () async => progression,
            onUltra: () async => progression,
            onPurchasePermanentUpgrade: (_, __) async => progression,
          ),
        ),
      ];

      for (final viewport in _viewports) {
        tester.view.physicalSize = Size(
          viewport.width.toDouble(),
          viewport.height.toDouble(),
        );

        for (final screen in screens) {
          await tester.pumpWidget(_app(screen.build()));
          // Fixed, bounded frames keep the smoke suite deterministic and fast;
          // pumpAndSettle can hang on intentionally repeating UI animations.
          await tester.pump(const Duration(milliseconds: 120));
          expect(
            tester.takeException(),
            isNull,
            reason:
                '${screen.name} raised a layout exception at '
                '${viewport.width}x${viewport.height}.',
          );
        }
      }
    },
  );

  testWidgets('More navigation opens without a mobile or desktop overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controllers = <TextEditingController>[];
    addTearDown(() {
      for (final controller in controllers) {
        controller.dispose();
      }
    });

    for (final viewport in _viewports) {
      tester.view.physicalSize = Size(
        viewport.width.toDouble(),
        viewport.height.toDouble(),
      );
      await tester.pumpWidget(_app(_dashboard(controllers)));
      await tester.pump(const Duration(milliseconds: 80));

      final more = find.text('More').first;
      expect(more, findsOneWidget);
      await tester.tap(more);
      await tester.pump(const Duration(milliseconds: 180));
      expect(
        tester.takeException(),
        isNull,
        reason:
            'More navigation raised a layout exception at '
            '${viewport.width}x${viewport.height}.',
      );
    }
  });
}
