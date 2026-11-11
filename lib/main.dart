import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'arcade/arcade_page.dart';
import 'core/automation/bot_team.dart';
import 'core/automation/clock_rollback_policy.dart';
import 'core/automation/guessing_bot.dart';
import 'core/automation/offline_earnings_policy.dart';
import 'core/game/difficulty_rules.dart';
import 'core/game/game_engine.dart';
import 'core/game/guess_economy_rules.dart';
import 'core/legacy/invisible_trait_engine.dart';
import 'core/legacy/legacy_systems_engine.dart';
import 'core/numbers/big_number.dart';
import 'core/progression/progression_calculator.dart';
import 'core/progression/progression_engine.dart';
import 'core/progression/progression_state.dart';
import 'data/saves/save_data.dart';
import 'data/saves/save_storage.dart';
import 'dev/developer_settings_page.dart';
import 'home/game_dashboard_page.dart';
import 'i18n/app_localizations.dart';
import 'legacy/legacy_pages.dart';
import 'legacy/legacy_systems_page.dart';
import 'progression/progression_hub_page.dart';
import 'saves/save_slots_page.dart';
import 'settings/game_settings.dart';
import 'settings/menu_studio_page.dart';
import 'settings/music_settings_sync.dart';
import 'settings/settings_page.dart';
import 'shop/nebula_shop_page.dart';
import 'shop/upgrade_catalog.dart';
import 'shop/upgrade_shop_page.dart';
import 'worlds/world_boss_battle_engine.dart';
import 'worlds/world_map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalizations.load('en_us');
  await UpgradeCatalog.load();
  runApp(const GtnApp());
}

class GtnApp extends StatelessWidget {
  const GtnApp({super.key});

  static final ValueNotifier<GameSettings> settingsNotifier =
      ValueNotifier<GameSettings>(GameSettings.initial);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: AppLocalizations.catalog,
      builder: (context, translations, _) =>
          ValueListenableBuilder<GameSettings>(
            valueListenable: settingsNotifier,
            builder: (context, settings, _) {
              return M3EMaterialApp(
                title: 'GuessTheNumber 2',
                data: M3EThemeData.light(
                  seedColor: Color(
                    0xFF000000 |
                        int.parse(
                          settings.customPrimaryColor.substring(1),
                          radix: 16,
                        ),
                  ),
                ),
                fontFamily: 'Manrope',
                autoTheming: false,
                dynamicColoring: false,
                initialTheme: settings.themeMode == 'System'
                    ? MediaQuery.platformBrightnessOf(context)
                    : settings.darkMode
                    ? Brightness.dark
                    : Brightness.light,
                debugShowCheckedModeBanner: false,
                appBuilder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: settings.reduceMotion),
                  child: child ?? const SizedBox.shrink(),
                ),
                home: const GameHomePage(),
              );
            },
          ),
    );
  }
}

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});

  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage>
    with WidgetsBindingObserver {
  GameEngine _engine = GameEngine();

  int _rangeMaximum(ProgressionState progression, GameSettings settings) =>
      DifficultyRules.rangeMaximum(
        settings.difficultyId,
        progression.upgrades['better_range'] ?? 0,
      ) *
      _legacySystemsEngine.rangeMultiplier(progression.legacySystems);

  GameEngine _engineFor(ProgressionState progression, GameSettings settings) =>
      GameEngine(maximum: _rangeMaximum(progression, settings));

  GameState _createGame() =>
      _newGameWithAdaptiveTarget(_engineFor(_progression, _settings).newGame());

  GameState _newGameWithAdaptiveTarget(GameState candidate) {
    final systems = _progression.legacySystems;
    final profile = systems.adaptiveTraitProfile;
    final secret = _invisibleTraitEngine.adjustNextTarget(
      profile: profile,
      candidate: candidate.secret,
      rangeMin: candidate.minimum,
      rangeMax: candidate.maximum,
    );
    return GameState(
      secret: secret,
      attempts: 0,
      isComplete: false,
      minimum: candidate.minimum,
      maximum: candidate.maximum,
    );
  }

  final ProgressionEngine _progressionEngine = const ProgressionEngine();
  final WorldBossBattleEngine _worldBossBattleEngine =
      const WorldBossBattleEngine();
  final LegacySystemsEngine _legacySystemsEngine = const LegacySystemsEngine();
  final InvisibleTraitEngine _invisibleTraitEngine =
      const InvisibleTraitEngine();
  final BotTeam _botTeam = BotTeam();
  Timer? _autoClickerTimer;
  Timer? _playtimeTimer;
  bool _autoClickerTickRunning = false;
  bool _resumeCatchUpPending = false;
  ProgressionState _progression = ProgressionState.initial;
  GameSettings _settings = GameSettings.initial;
  final TextEditingController _controller = TextEditingController();
  late GameState _game = _createGame();
  late Future<SaveStorage> _storage = SaveStorage.inApplicationDocuments();
  int _activeSlot = 1;
  int _gamesWon = 0;
  bool _isLoading = true;
  String _message = 'Make your move.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreSave();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeAutoClicker());
      _startPlaytimeTimer();
    } else {
      _autoClickerTimer?.cancel();
      _autoClickerTimer = null;
      _playtimeTimer?.cancel();
      _playtimeTimer = null;
    }
  }

  void _startPlaytimeTimer() {
    if (!mounted || _isLoading || _playtimeTimer?.isActive == true) return;
    _playtimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isLoading) return;
      final next = _progression.copyWith(
        playtimeSeconds: _progression.playtimeSeconds + 1,
      );
      final evaluated = _progressionEngine.evaluateAchievements(next);
      final unlocked =
          evaluated.achievements.length > _progression.achievements.length;
      setState(() => _progression = evaluated);
      if (unlocked || evaluated.playtimeSeconds % 30 == 0) {
        unawaited(_persist());
      }
    });
  }

  Future<void> _resumeAutoClicker() async {
    if (!mounted || _isLoading) return;
    if (_autoClickerTickRunning) {
      _resumeCatchUpPending = true;
      return;
    }
    final systems = _progression.legacySystems;
    final now = DateTime.now().millisecondsSinceEpoch;
    final savedAt = systems.lastSaveTimestamp;
    final clockCheck = ClockRollbackPolicy.check(
      nowMillis: now,
      lastSaveTimestamp: savedAt,
      timeTravelPenaltyUntil: systems.timeTravelPenaltyUntil,
      autoClickerActive: systems.autoClickerActive,
    );
    if (clockCheck.detected) {
      setState(() {
        _progression = _progression.copyWith(
          legacySystems: systems.copyWith(
            autoClickerActive: clockCheck.autoClickerActive,
            lastSaveTimestamp: clockCheck.lastSaveTimestamp,
            timeTravelPenaltyUntil: clockCheck.timeTravelPenaltyUntil,
          ),
        );
        _message = 'Clock rollback detected. Auto Clicker paused for 24 hours.';
      });
      await _persist();
    } else {
      final offlineEarnings = systems.autoClickerActive && savedAt > 0
          ? OfflineEarningsPolicy.calculate(
              autoClickerWasActive: true,
              elapsedSeconds: (now - savedAt) ~/ 1000,
            )
          : BigNumber.fromInt(0);
      if (offlineEarnings.compareTo(BigNumber.fromInt(0)) > 0) {
        setState(() {
          _progression = _progression.copyWith(
            money: _progression.money + offlineEarnings,
            moneyEarned: _progression.moneyEarned + offlineEarnings,
          );
          _message =
              'Auto Clicker earned $offlineEarnings Money while the app was away.';
        });
      }
      await _persist();
    }
    _scheduleAutoClicker();
  }

  Future<void> _restoreSave() async {
    var shouldPersistOfflineEarnings = false;
    try {
      final firstSlotStorage = await _storage;
      final activeSlot = await firstSlotStorage.loadActiveSlot();
      final storage = activeSlot == firstSlotStorage.slot
          ? firstSlotStorage
          : await SaveStorage.inApplicationDocuments(slot: activeSlot);
      final save = await storage.load();
      if (!mounted) return;
      setState(() {
        _storage = Future.value(storage);
        _activeSlot = activeSlot;
      });
      if (save != null) {
        var restoredProgression = _worldBossBattleEngine
            .migrateLegacyWorldUnlocks(save.progression);
        final savedAt = restoredProgression.legacySystems.lastSaveTimestamp;
        final now = DateTime.now().millisecondsSinceEpoch;
        final clockCheck = ClockRollbackPolicy.check(
          nowMillis: now,
          lastSaveTimestamp: savedAt,
          timeTravelPenaltyUntil:
              restoredProgression.legacySystems.timeTravelPenaltyUntil,
          autoClickerActive:
              restoredProgression.legacySystems.autoClickerActive,
        );
        final timeTravelDetected = clockCheck.detected;
        restoredProgression = restoredProgression.copyWith(
          legacySystems: restoredProgression.legacySystems.copyWith(
            autoClickerActive: clockCheck.autoClickerActive,
            lastSaveTimestamp: clockCheck.lastSaveTimestamp,
            timeTravelPenaltyUntil: clockCheck.timeTravelPenaltyUntil,
          ),
        );
        final elapsedSeconds = savedAt > 0 && !timeTravelDetected
            ? ((now - savedAt) ~/ 1000)
            : 0;
        final offlineEarnings = timeTravelDetected
            ? BigNumber.fromInt(0)
            : OfflineEarningsPolicy.calculate(
                autoClickerWasActive:
                    restoredProgression.legacySystems.autoClickerActive,
                elapsedSeconds: elapsedSeconds,
              );
        if (offlineEarnings.compareTo(BigNumber.fromInt(0)) > 0) {
          restoredProgression = restoredProgression.copyWith(
            money: restoredProgression.money + offlineEarnings,
            moneyEarned: restoredProgression.moneyEarned + offlineEarnings,
          );
        }
        final restoredSystems = restoreMusicStateFromSettings(
          settings: save.settings,
          systems: restoredProgression.legacySystems,
        );
        restoredProgression = restoredProgression.copyWith(
          legacySystems: restoredSystems,
        );
        final restoredSettings = syncMusicSettingsFromLegacy(
          settings: save.settings,
          systems: restoredSystems,
        );
        final restoredEngine = _engineFor(
          restoredProgression,
          restoredSettings,
        );
        await AppLocalizations.load(restoredSettings.localeCode);
        if (!mounted) return;
        setState(() {
          _engine = restoredEngine;
          _game = _engine.restore(
            secret: save.secret,
            attempts: save.attempts,
            isComplete: save.isComplete,
            savedMinimum: save.minimum,
            savedMaximum: save.maximum,
          );
          _gamesWon = save.gamesWon;
          _progression = restoredProgression;
          _settings = restoredSettings;
          GtnApp.settingsNotifier.value = _settings;
          _message = timeTravelDetected
              ? 'Clock rollback detected. Auto Clicker paused for 24 hours.'
              : offlineEarnings.compareTo(BigNumber.fromInt(0)) > 0
              ? 'Welcome back! Your Auto Clicker earned $offlineEarnings Money while you were away.'
              : 'Welcome back! Your saved game is ready.';
        });
        shouldPersistOfflineEarnings = true;
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _message = 'A new game is ready. Your save could not be loaded.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _startPlaytimeTimer();
      }
    }
    _botTeam.reset(_game.minimum, _game.maximum);
    if (shouldPersistOfflineEarnings) await _persist();
    _scheduleAutoClicker();
  }

  Future<void> _persist() async {
    final evaluated = _progressionEngine.evaluateAchievements(_progression);
    if (evaluated != _progression) {
      _progression = evaluated;
      if (mounted) setState(() {});
    }
    try {
      final storage = await _storage;
      _progression = _progression.copyWith(
        legacySystems: _progression.legacySystems.copyWith(
          lastSaveTimestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await storage.update((existing) {
        final base =
            existing ??
            SaveData(
              secret: _game.secret,
              attempts: _game.attempts,
              gamesWon: _gamesWon,
              isComplete: _game.isComplete,
              minimum: _game.minimum,
              maximum: _game.maximum,
              progression: _progression,
              settings: _settings,
            );
        return base.copyWith(
          secret: _game.secret,
          attempts: _game.attempts,
          gamesWon: _gamesWon,
          isComplete: _game.isComplete,
          minimum: _game.minimum,
          maximum: _game.maximum,
          progression: _progression,
          settings: _settings,
        );
      });
    } on Exception {
      if (mounted) {
        setState(() => _message = 'Game is still playable, but saving failed.');
      }
    }
  }

  Future<ProgressionState> _purchaseUpgrade(
    UpgradeDefinition definition,
  ) async {
    final updated = _progressionEngine.purchaseUpgrade(
      _progression,
      definition,
    );
    if (updated != _progression) {
      final previousRange = _rangeMaximum(_progression, _settings);
      final nextRange = _rangeMaximum(updated, _settings);
      final withQuestProgress = updated.copyWith(
        legacySystems: _legacySystemsEngine
            .recordUpgradePurchase(updated.legacySystems)
            .copyWith(
              adaptiveTraitProfile: _invisibleTraitEngine
                  .observeUpgradePurchase(
                    updated.legacySystems.adaptiveTraitProfile,
                  ),
            ),
      );
      setState(() {
        _progression = withQuestProgress;
        if (previousRange != nextRange) {
          _engine = _engineFor(withQuestProgress, _settings);
          _game = _newGameWithAdaptiveTarget(_engine.newGame());
          _botTeam.reset(_game.minimum, _game.maximum);
          _message = 'Your range upgrade is active. A fresh round is ready.';
        }
      });
      await _persist();
    }
    return _progression;
  }

  Future<void> _prestige() async {
    var updated = _progressionEngine.prestige(
      _progression,
      ProgressionCalculator.prestigeRules(_progression),
    );
    if (updated != _progression) {
      final existingProfile = _progression.legacySystems.adaptiveTraitProfile;
      final profile = _invisibleTraitEngine.observeProgression(
        updated.legacySystems.adaptiveTraitProfile,
        prestigeDelta:
            updated.prestigeResets > existingProfile.prestigesObserved
            ? updated.prestigeResets - existingProfile.prestigesObserved
            : 0,
        ultraDelta: updated.ultraResets > existingProfile.ultrasObserved
            ? updated.ultraResets - existingProfile.ultrasObserved
            : 0,
      );
      updated = updated.copyWith(
        legacySystems: updated.legacySystems.copyWith(
          adaptiveTraitProfile: profile,
        ),
      );
      setState(() {
        _progression = updated;
        _engine = _engineFor(updated, _settings);
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
        _botTeam.reset(_game.minimum, _game.maximum);
        _message = 'Prestige complete! Build your progress again.';
      });
      await _persist();
    }
  }

  Future<void> _ultra() async {
    if (_progression.prestige.compareTo(BigNumber.fromInt(1000)) < 0) return;
    var updated = _progressionEngine.ultra(
      _progression,
      ProgressionCalculator.ultraRules(_progression),
    );
    if (updated != _progression) {
      final existingProfile = _progression.legacySystems.adaptiveTraitProfile;
      final profile = _invisibleTraitEngine.observeProgression(
        updated.legacySystems.adaptiveTraitProfile,
        prestigeDelta:
            _progression.prestigeResets > existingProfile.prestigesObserved
            ? _progression.prestigeResets - existingProfile.prestigesObserved
            : 0,
        ultraDelta: updated.ultraResets > existingProfile.ultrasObserved
            ? updated.ultraResets - existingProfile.ultrasObserved
            : 0,
      );
      updated = updated.copyWith(
        legacySystems: updated.legacySystems.copyWith(
          adaptiveTraitProfile: profile,
        ),
      );
      setState(() {
        _progression = updated;
        _engine = _engineFor(updated, _settings);
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
        _botTeam.reset(_game.minimum, _game.maximum);
        _message = 'Ultra reset complete! A new run begins.';
      });
      await _persist();
    }
  }

  Future<ProgressionState> _purchasePermanentUpgrade(
    GameUpgrade upgrade,
    bool ultra,
  ) async {
    final updated = ultra
        ? _progressionEngine.purchaseUltraUpgrade(
            _progression,
            upgrade.definition,
          )
        : _progressionEngine.purchasePrestigeUpgrade(
            _progression,
            upgrade.definition,
          );
    if (updated != _progression) {
      setState(() => _progression = updated);
      await _persist();
    }
    return _progression;
  }

  Future<void> _openProgressionHub() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProgressionHubPage(
          progression: _progression,
          onPrestige: () async {
            await _prestige();
            return _progression;
          },
          onUltra: () async {
            await _ultra();
            return _progression;
          },
          onPurchasePermanentUpgrade: _purchasePermanentUpgrade,
        ),
      ),
    );
  }

  Future<void> _awardArcadeReward(BigNumber nebula, BigNumber money) async {
    setState(() {
      _progression = _progressionEngine.awardArcadeReward(
        _progression,
        nebulaReward: nebula,
        moneyReward: money,
      );
    });
    await _persist();
  }

  Future<void> _openArcade() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ArcadePage(onReward: _awardArcadeReward),
      ),
    );
  }

  Future<ProgressionState> _purchaseNebulaItem(NebulaShopItem item) async {
    final systems = _progression.legacySystems;
    final ownedBot = NebulaShopCatalog.botIds.any(
      (id) => (_progression.nebulaItems[id] ?? 0) > 0,
    );
    if (NebulaShopCatalog.botUpgradeIds.contains(item.id) && !ownedBot) {
      return _progression;
    }
    if (NebulaShopCatalog.automationIds.contains(item.id) &&
        (_progression.nebulaItems[item.id] ?? 0) > 0) {
      return _progression;
    }
    var updated = _progressionEngine.purchaseNebulaItem(
      _progression,
      itemId: item.id,
      price: item.price,
    );
    if (updated != _progression) {
      final isBotPurchase = NebulaShopCatalog.botIds.contains(item.id);
      final nextSpeed = item.id == 'bot_speed_upgrade'
          ? (systems.autoClickerSpeed * 1.5).clamp(1.0, 5.0).toDouble()
          : systems.autoClickerSpeed;
      updated = updated.copyWith(
        legacySystems: systems.copyWith(
          autoClickerActive: isBotPurchase ? true : systems.autoClickerActive,
          autoClickerSpeed: nextSpeed,
        ),
      );
      setState(() => _progression = updated);
      await _persist();
      _scheduleAutoClicker();
    }
    return _progression;
  }

  Future<ProgressionState> _setAutomationActive(bool active) async {
    final hasBot = NebulaShopCatalog.botIds.any(
      (id) => (_progression.nebulaItems[id] ?? 0) > 0,
    );
    if (!hasBot) return _progression;
    if (active &&
        _progression.legacySystems.timeTravelPenaltyUntil >
            DateTime.now().millisecondsSinceEpoch) {
      if (mounted) {
        setState(
          () => _message =
              'Auto Clicker is temporarily paused after a clock rollback.',
        );
      }
      return _progression;
    }
    setState(() {
      _progression = _progression.copyWith(
        legacySystems: _progression.legacySystems.copyWith(
          autoClickerActive: active,
        ),
      );
    });
    await _persist();
    _scheduleAutoClicker();
    return _progression;
  }

  void _scheduleAutoClicker() {
    _autoClickerTimer?.cancel();
    _autoClickerTimer = null;
    if (!mounted ||
        _isLoading ||
        _autoClickerTickRunning ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.detached) {
      return;
    }
    final systems = _progression.legacySystems;
    if (!systems.autoClickerActive ||
        systems.timeTravelPenaltyUntil >
            DateTime.now().millisecondsSinceEpoch) {
      return;
    }
    final purchasedBots = NebulaShopCatalog.botIds
        .where((id) => (_progression.nebulaItems[id] ?? 0) > 0)
        .toSet();
    if (purchasedBots.isEmpty) purchasedBots.add('auto_clicker_basic');
    final delay = _botTeam.delayMillis(
      active: true,
      speed: systems.autoClickerSpeed,
      speedTalentOne: systems.talents.contains('talent_speed_1'),
      speedTalentTwo: systems.talents.contains('talent_speed_2'),
      speedMutator: systems.activeMutators.contains('mut_speed'),
    );
    _autoClickerTimer = Timer(Duration(milliseconds: delay), () async {
      if (_autoClickerTickRunning) return;
      _autoClickerTimer = null;
      _autoClickerTickRunning = true;
      try {
        await _runAutoClickerTick();
      } finally {
        _autoClickerTickRunning = false;
        if (_resumeCatchUpPending) {
          _resumeCatchUpPending = false;
          unawaited(_resumeAutoClicker());
        } else {
          _scheduleAutoClicker();
        }
      }
    });
  }

  Future<void> _runAutoClickerTick() async {
    if (!mounted ||
        _isLoading ||
        !_progression.legacySystems.autoClickerActive) {
      return;
    }
    if (_game.isComplete) {
      setState(() {
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
        _botTeam.reset(_game.minimum, _game.maximum);
        _message = 'Auto Clicker started a new round.';
      });
    }
    final systems = _progression.legacySystems;
    final purchasedBots = NebulaShopCatalog.botIds
        .where((id) => (_progression.nebulaItems[id] ?? 0) > 0)
        .toSet();
    if (purchasedBots.isEmpty) purchasedBots.add('auto_clicker_basic');
    final action = _botTeam.nextAction(
      purchasedBots: purchasedBots,
      sharedMemory: (_progression.nebulaItems['bot_logic_upgrade'] ?? 0) > 0,
      sequence: systems.botActionSequence,
      rangeMinimum: 1,
      rangeMaximum: _rangeMaximum(_progression, _settings),
      currentMinimum: _game.minimum,
      currentMaximum: _game.maximum,
      speed: systems.autoClickerSpeed,
      speedTalentOne: systems.talents.contains('talent_speed_1'),
      speedTalentTwo: systems.talents.contains('talent_speed_2'),
      speedMutator: systems.activeMutators.contains('mut_speed'),
    );
    if (action == null) return;
    await _submitGuess(automatedGuess: action.guess, botId: action.botId);
  }

  Future<void> _openNebulaShop() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NebulaShopPage(
          progression: _progression,
          onPurchase: _purchaseNebulaItem,
          onAutomationChanged: _setAutomationActive,
        ),
      ),
    );
  }

  Future<ProgressionState> _worldBossAction(
    String worldId,
    String action,
  ) async {
    if (action == 'mastery') {
      final masteryResult = _legacySystemsEngine.upgradeWorldMastery(
        progression: _progression,
        systems: _progression.legacySystems,
        worldId: worldId,
      );
      if (masteryResult.accepted) {
        setState(() {
          _progression = masteryResult.progression.copyWith(
            legacySystems: masteryResult.systems,
          );
          _message = masteryResult.message;
        });
        await _persist();
      }
      return _progression;
    }
    final result = switch (action) {
      'secret' => _worldBossBattleEngine.discoverSecret(_progression, worldId),
      'unlock' => _worldBossBattleEngine.unlockWorld(_progression, worldId),
      'select_world' => _worldBossBattleEngine.selectWorld(
        _progression,
        worldId,
      ),
      _ => _worldBossBattleEngine.toggleBossBattle(_progression, worldId),
    };
    if (result.accepted) {
      setState(() {
        _progression = result.progression;
        _message = result.message;
      });
      await _persist();
    }
    return _progression;
  }

  Future<void> _openWorldMap() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            WorldMapPage(progression: _progression, onAction: _worldBossAction),
      ),
    );
  }

  Future<void> _switchSaveSlot(int slot) async {
    setState(() => _isLoading = true);
    try {
      final storage = await SaveStorage.inApplicationDocuments(slot: slot);
      final save = await storage.load();
      if (!mounted) return;
      var nextProgression = _worldBossBattleEngine.migrateLegacyWorldUnlocks(
        save?.progression ?? ProgressionState.initial,
      );
      final savedAt = nextProgression.legacySystems.lastSaveTimestamp;
      final now = DateTime.now().millisecondsSinceEpoch;
      final clockCheck = ClockRollbackPolicy.check(
        nowMillis: now,
        lastSaveTimestamp: savedAt,
        timeTravelPenaltyUntil:
            nextProgression.legacySystems.timeTravelPenaltyUntil,
        autoClickerActive: nextProgression.legacySystems.autoClickerActive,
      );
      final timeTravelDetected = clockCheck.detected;
      nextProgression = nextProgression.copyWith(
        legacySystems: nextProgression.legacySystems.copyWith(
          autoClickerActive: clockCheck.autoClickerActive,
          lastSaveTimestamp: clockCheck.lastSaveTimestamp,
          timeTravelPenaltyUntil: clockCheck.timeTravelPenaltyUntil,
        ),
      );
      final elapsedSeconds = savedAt > 0 && !timeTravelDetected
          ? ((now - savedAt) ~/ 1000)
          : 0;
      final offlineEarnings = timeTravelDetected
          ? BigNumber.fromInt(0)
          : OfflineEarningsPolicy.calculate(
              autoClickerWasActive:
                  nextProgression.legacySystems.autoClickerActive,
              elapsedSeconds: elapsedSeconds,
            );
      if (offlineEarnings.compareTo(BigNumber.fromInt(0)) > 0) {
        nextProgression = nextProgression.copyWith(
          money: nextProgression.money + offlineEarnings,
          moneyEarned: nextProgression.moneyEarned + offlineEarnings,
        );
      }
      await AppLocalizations.load(save?.settings.localeCode ?? 'en_us');
      await storage.saveActiveSlot(slot);
      if (!mounted) return;
      final nextSettings = save?.settings ?? GameSettings.initial;
      final nextEngine = _engineFor(nextProgression, nextSettings);
      setState(() {
        _storage = Future.value(storage);
        _activeSlot = slot;
        _engine = nextEngine;
        _game = save == null
            ? _newGameWithAdaptiveTarget(_engine.newGame())
            : _engine.restore(
                secret: save.secret,
                attempts: save.attempts,
                isComplete: save.isComplete,
                savedMinimum: save.minimum,
                savedMaximum: save.maximum,
              );
        _gamesWon = save?.gamesWon ?? 0;
        _progression = nextProgression;
        _settings = nextSettings;
        GtnApp.settingsNotifier.value = _settings;
        _message = timeTravelDetected
            ? 'Clock rollback detected. Auto Clicker paused for 24 hours.'
            : offlineEarnings.compareTo(BigNumber.fromInt(0)) > 0
            ? 'Save slot $slot loaded. Auto Clicker earned $offlineEarnings Money offline.'
            : save == null
            ? 'New save slot ready. Guess a number between 1 and 100.'
            : 'Save slot $slot loaded.';
        _isLoading = false;
      });
      await _persist();
      _botTeam.reset(_game.minimum, _game.maximum);
      _scheduleAutoClicker();
    } on Exception {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'Could not load save slot $slot.';
        });
      }
    }
  }

  Future<void> _openSaveSlots() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            SaveSlotsPage(activeSlot: _activeSlot, onSelect: _switchSaveSlot),
      ),
    );
  }

  Future<void> _updateSettings(GameSettings settings) async {
    await AppLocalizations.load(settings.localeCode);
    if (!mounted) return;
    final difficultyChanged = settings.difficultyId != _settings.difficultyId;
    final restoredSystems = restoreMusicStateFromSettings(
      settings: settings,
      systems: _progression.legacySystems,
    );
    final nextProgression = _progression.copyWith(
      legacySystems: restoredSystems,
    );
    final synchronizedSettings = syncMusicSettingsFromLegacy(
      settings: settings,
      systems: restoredSystems,
    );
    setState(() {
      _progression = nextProgression;
      _settings = synchronizedSettings;
      if (difficultyChanged) {
        _engine = _engineFor(nextProgression, synchronizedSettings);
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
        _botTeam.reset(_game.minimum, _game.maximum);
        _message =
            'Difficulty changed to ${DifficultyRules.name(settings.difficultyId)}. A fresh round is ready.';
      }
    });
    GtnApp.settingsNotifier.value = synchronizedSettings;
    await _persist();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          settings: _settings,
          onChanged: _updateSettings,
          onOpenMenuStudio: _openMenuStudio,
        ),
      ),
    );
  }

  Future<void> _openMenuStudio() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            MenuStudioPage(settings: _settings, onChanged: _updateSettings),
      ),
    );
  }

  SaveData _currentSaveData() => SaveData(
    secret: _game.secret,
    attempts: _game.attempts,
    gamesWon: _gamesWon,
    isComplete: _game.isComplete,
    minimum: _game.minimum,
    maximum: _game.maximum,
    progression: _progression,
    settings: _settings,
  );

  Future<void> _applyDeveloperSave(SaveData save) async {
    final restoredSystems = restoreMusicStateFromSettings(
      settings: save.settings,
      systems: save.progression.legacySystems,
    );
    final restoredProgression = save.progression.copyWith(
      legacySystems: restoredSystems,
    );
    final restoredSettings = syncMusicSettingsFromLegacy(
      settings: save.settings,
      systems: restoredSystems,
    );
    setState(() {
      _game = _engine.restore(
        secret: save.secret,
        attempts: save.attempts,
        isComplete: save.isComplete,
        savedMinimum: save.minimum,
        savedMaximum: save.maximum,
      );
      _gamesWon = save.gamesWon;
      _progression = restoredProgression;
      _settings = restoredSettings;
      GtnApp.settingsNotifier.value = _settings;
      _message = 'Developer save applied.';
    });
    await _persist();
  }

  Future<String> _runDeveloperCommand(String command) async {
    final parts = command.trim().split(RegExp(r'\\s+'));
    final action = parts.first.toLowerCase();
    if (action == '/help') {
      return '/money N · /prestige N · /ultra N · /nebula N · /attempts N · /wins N · /reset';
    }
    if (action == '/reset') {
      final resetSystems = restoreMusicStateFromSettings(
        settings: _settings,
        systems: ProgressionState.initial.legacySystems,
      );
      setState(() {
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
        _progression = ProgressionState.initial.copyWith(
          legacySystems: resetSystems,
        );
        _gamesWon = 0;
        _message = 'Developer reset completed.';
      });
      await _persist();
      return 'Current slot reset.';
    }
    if (parts.length != 2) return 'Usage: $action <value>';
    try {
      switch (action) {
        case '/money':
        case '/prestige':
        case '/ultra':
        case '/nebula':
          final amount = BigNumber.parse(parts[1]);
          if (amount.compareTo(BigNumber.fromInt(0)) < 0) {
            return 'Currency values cannot be negative.';
          }
          setState(() {
            _progression = switch (action) {
              '/money' => _progression.copyWith(money: amount),
              '/prestige' => _progression.copyWith(prestige: amount),
              '/ultra' => _progression.copyWith(ultra: amount),
              _ => _progression.copyWith(nebula: amount),
            };
          });
          await _persist();
          return '$action set to $amount.';
        case '/attempts':
          final value = int.parse(parts[1]);
          if (value < 0) return 'Attempts cannot be negative.';
          setState(() {
            _game = _engine.restore(
              secret: _game.secret,
              attempts: value,
              isComplete: _game.isComplete,
            );
          });
          await _persist();
          return 'Attempts set to $value.';
        case '/wins':
          final value = int.parse(parts[1]);
          if (value < 0) return 'Wins cannot be negative.';
          setState(() => _gamesWon = value);
          await _persist();
          return 'Games won set to $value.';
        default:
          return 'Unknown command. Try /help.';
      }
    } on FormatException {
      return 'Invalid value. Use a whole number or decimal.';
    } on ArgumentError {
      return 'That value is not valid for the current game.';
    }
  }

  Future<void> _openDeveloperSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DeveloperSettingsPage(
          save: _currentSaveData(),
          onCommand: _runDeveloperCommand,
          onApplySave: _applyDeveloperSave,
        ),
      ),
    );
  }

  Future<void> _applyLegacyProgression(ProgressionState progression) async {
    if (progression.legacySystems.autoClickerActive &&
        progression.legacySystems.timeTravelPenaltyUntil >
            DateTime.now().millisecondsSinceEpoch) {
      progression = progression.copyWith(
        legacySystems: progression.legacySystems.copyWith(
          autoClickerActive: false,
        ),
      );
      setState(
        () => _message =
            'Auto Clicker is temporarily paused after a clock rollback.',
      );
    }
    final synchronizedSettings = syncMusicSettingsFromLegacy(
      settings: _settings,
      systems: progression.legacySystems,
    );
    final oldRange = _rangeMaximum(_progression, _settings);
    final newRange = _rangeMaximum(progression, synchronizedSettings);
    setState(() {
      _progression = progression;
      _settings = synchronizedSettings;
      GtnApp.settingsNotifier.value = synchronizedSettings;
      if (oldRange != newRange) {
        _engine = _engineFor(progression, synchronizedSettings);
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
        _botTeam.reset(_game.minimum, _game.maximum);
        _message = 'Hardcore range changed. A fresh round is ready.';
      }
    });
    await _persist();
    _scheduleAutoClicker();
  }

  Future<void> _openLegacyPages() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LegacyHubPage(
          progression: _progression,
          activeSlot: _activeSlot,
          onSystemsChanged: _applyLegacyProgression,
        ),
      ),
    );
    _scheduleAutoClicker();
  }

  Future<void> _openLegacySystems(LegacySystemsView view) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LegacySystemsPage(
          progression: _progression,
          onChanged: _applyLegacyProgression,
          view: view,
        ),
      ),
    );
    _scheduleAutoClicker();
  }

  Future<void> _openSystems() => _openLegacySystems(LegacySystemsView.all);

  Future<void> _openMusic() => _openLegacySystems(LegacySystemsView.music);

  Future<void> _openLuckyStake() =>
      _openLegacySystems(LegacySystemsView.luckyStake);

  Future<void> _openUpgradeShop() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UpgradeShopPage(
          progression: _progression,
          onPurchase: _purchaseUpgrade,
        ),
      ),
    );
  }

  String? _currentSeasonId() => switch (DateTime.now().month) {
    12 || 1 || 2 => 'winter',
    3 || 4 || 5 => 'spring',
    6 || 7 || 8 => 'summer',
    _ => 'autumn',
  };

  Future<void> _submitGuess({int? automatedGuess, String? botId}) async {
    final isBot = botId != null;
    final guess = automatedGuess ?? int.tryParse(_controller.text.trim());
    if (guess == null) {
      setState(
        () => _message =
            'Enter a whole number from ${_game.minimum} to ${_game.maximum}.',
      );
      return;
    }

    GuessResult? resultForMessage;
    setState(() {
      var rangeScoutActive = false;
      final previousAttempts = _game.attempts;
      _game = _engine.guess(_game, guess);
      resultForMessage = _game.lastResult;
      if (_game.attempts > previousAttempts) {
        final correct = resultForMessage == GuessResult.correct;
        final beforeGuess = _progression;
        final legacySystems = beforeGuess.legacySystems;
        final traitEffects = _legacySystemsEngine.evaluateTraits(
          progression: beforeGuess,
          systems: legacySystems,
          playerLevel: 1,
          activeSeasonId: _currentSeasonId(),
        );
        rangeScoutActive = traitEffects.rangeHint;
        final criticalPrecisionLevel =
            beforeGuess.prestigeUpgrades['critical_precision_boost'] ?? 0;
        final guaranteedGoldenGuess =
            !isBot &&
            (beforeGuess.nebulaItems['golden_guess'] ?? 0) > 0 &&
            (beforeGuess.totalGuesses + 1) % 10 == 0;
        final isCritical =
            correct &&
            (guaranteedGoldenGuess ||
                Random.secure().nextDouble() <
                    GuessEconomyRules.criticalChance(criticalPrecisionLevel));
        final rawReward = correct
            ? GuessEconomyRules.correctGuessReward(
                rangeMaximum: _game.maximum,
                currentStreak: beforeGuess.currentStreak,
                rewardMultiplierLevel:
                    beforeGuess.upgrades['reward_multiplier'] ?? 0,
                // talent_reward_1 is a Prestige talent, not the legacy shop/upgrade flag
                // consumed by GameEngine's base reward calculation. GTN1 applies its
                // +50% once in applyTalentBonuses after the raw reward is recorded.
                hasTalentReward: false,
                isCritical: isCritical,
                difficultyId: _settings.difficultyId,
                mutatorMultiplier: _legacySystemsEngine.mutatorRewardMultiplier(
                  legacySystems,
                ),
                traitMultiplier: BigNumber.parse(
                  traitEffects.correctGuessMultiplier.toStringAsFixed(2),
                ),
                permanentMoneyMultiplier:
                    GuessEconomyRules.moneyEarningMultiplier(beforeGuess),
              )
            : null;
        var afterReward = _progressionEngine.recordGuess(
          beforeGuess,
          correct: correct,
          baseReward: rawReward,
          isBot: isBot,
        );
        final adaptiveProfile = _invisibleTraitEngine.observeGuess(
          profile: legacySystems.adaptiveTraitProfile,
          correct: correct,
          newStreak: afterReward.currentStreak,
          reward: correct
              ? afterReward.money - beforeGuess.money
              : BigNumber.fromInt(0),
        );
        final adaptiveDecision = _invisibleTraitEngine.evaluate(
          profile: adaptiveProfile,
          prestigeCount:
              adaptiveProfile.prestigesObserved > beforeGuess.prestigeResets
              ? adaptiveProfile.prestigesObserved
              : beforeGuess.prestigeResets,
          ultraCount: adaptiveProfile.ultrasObserved > beforeGuess.ultraResets
              ? adaptiveProfile.ultrasObserved
              : beforeGuess.ultraResets,
          currentStreak: afterReward.currentStreak,
        );
        rangeScoutActive =
            rangeScoutActive ||
            adaptiveDecision.helperIds.contains(
              InvisibleTraitEngine.helperRangeScout,
            );
        if (!correct && rangeScoutActive) {
          _game = _engine.applyRangeScoutHint(_game, guess);
        }
        if (correct) {
          final criticalChance = legacySystems.talents.contains('talent_crit_2')
              ? 0.15
              : legacySystems.talents.contains('talent_crit_1')
              ? 0.05
              : 0.0;
          afterReward = _legacySystemsEngine.applyCorrectGuessBonuses(
            before: beforeGuess,
            after: afterReward,
            systems: legacySystems,
            criticalHit: Random.secure().nextDouble() < criticalChance,
            crystalCoreProc:
                legacySystems.equippedRelics.contains('crystal_golem') &&
                Random.secure().nextDouble() < 0.10,
            nebulaBoostOwned:
                (beforeGuess.nebulaItems['nebula_boost'] ?? 0) > 0,
          );
          final adaptiveBonusRate = _invisibleTraitEngine.progressionBonusRate(
            helperIds: adaptiveDecision.helperIds,
            bonusCount: adaptiveDecision.bonusIds.length,
          );
          if (adaptiveBonusRate > 0) {
            final earned = afterReward.money - beforeGuess.money;
            final adaptiveBonus =
                earned * BigNumber.parse(adaptiveBonusRate.toStringAsFixed(2));
            afterReward = afterReward.copyWith(
              money: afterReward.money + adaptiveBonus,
              moneyEarned: afterReward.moneyEarned + adaptiveBonus,
            );
          }
        } else {
          final difficultyPenalty =
              beforeGuess.money *
              BigNumber.parse(
                DifficultyRules.wrongGuessPenalty(_settings.difficultyId)
                    .toStringAsFixed(2),
              );
          final taxPenalty = legacySystems.activeMutators.contains('mut_tax')
              ? beforeGuess.money * BigNumber.parse('0.05')
              : BigNumber.fromInt(0);
          final penalty = difficultyPenalty + taxPenalty;
          final refundRate = _legacySystemsEngine.resolveMissPenaltyRefundRate(
            traitRefundRate: traitEffects.missPenaltyRefundRate,
            adaptiveInsuranceActive: adaptiveDecision.helperIds.contains(
              InvisibleTraitEngine.helperMistakeInsurance,
            ),
          );
          final refund =
              penalty * BigNumber.parse(refundRate.toStringAsFixed(2));
          final extraPenalty =
              penalty *
              BigNumber.parse(
                traitEffects.riskMissPenaltyRate.toStringAsFixed(2),
              );
          final remainingMoney =
              beforeGuess.money - penalty + refund - extraPenalty;
          afterReward = afterReward.copyWith(
            money: remainingMoney.compareTo(BigNumber.fromInt(0)) < 0
                ? BigNumber.fromInt(0)
                : remainingMoney,
            currentStreak:
                traitEffects.streakProtection ||
                    adaptiveDecision.helperIds.contains(
                      InvisibleTraitEngine.helperStreakGuard,
                    )
                ? beforeGuess.currentStreak
                : afterReward.currentStreak,
          );
        }
        var adaptiveProfileAfter = _invisibleTraitEngine.markHelperUses(
          adaptiveProfile,
          adaptiveDecision.helperIds,
        );
        if (correct) {
          adaptiveProfileAfter = _invisibleTraitEngine.markBonusesAwarded(
            adaptiveProfileAfter,
            adaptiveDecision.bonusIds,
          );
        }
        var systemsAfter = _legacySystemsEngine
            .recordGuessProgress(
              legacySystems,
              correct: correct,
              currentStreak: afterReward.currentStreak,
              today: DateTime.now().toIso8601String().substring(0, 10),
              lootRoll: correct ? Random.secure().nextInt(1000) : null,
            )
            .copyWith(adaptiveTraitProfile: adaptiveProfileAfter);
        if (isBot) {
          final feedbackName = switch (resultForMessage) {
            GuessResult.tooLow => 'TOO_LOW',
            GuessResult.tooHigh => 'TOO_HIGH',
            GuessResult.correct => 'CORRECT',
            GuessResult.outOfRange || null => null,
          };
          if (feedbackName != null) {
            systemsAfter = systemsAfter.copyWith(
              botTotalGuesses: legacySystems.botTotalGuesses + 1,
              botCorrectGuesses:
                  legacySystems.botCorrectGuesses + (correct ? 1 : 0),
              botIncorrectGuesses:
                  legacySystems.botIncorrectGuesses + (correct ? 0 : 1),
              botActionSequence: legacySystems.botActionSequence + 1,
              lastBotGuess: guess,
              lastBotFeedback: feedbackName,
              lastBotId: botId,
            );
          }
        }
        systemsAfter = _legacySystemsEngine.discoverEligibleTraits(
          progression: afterReward,
          systems: systemsAfter,
          activeSeasonId: _currentSeasonId(),
        );
        var nextProgression = afterReward.copyWith(legacySystems: systemsAfter);
        final bossResult = _worldBossBattleEngine.recordGuess(
          nextProgression,
          correct: correct,
        );
        if (bossResult.accepted) nextProgression = bossResult.progression;
        _progression = nextProgression;
        if (isBot) {
          if (correct) {
            final nextGame = _newGameWithAdaptiveTarget(_engine.newGame());
            _game = _engine.continueAfterCorrect(
              _game,
              nextGame,
              attempts: previousAttempts,
            );
            _botTeam.reset(_game.minimum, _game.maximum);
          } else {
            _game = GameState(
              secret: _game.secret,
              attempts: previousAttempts,
              isComplete: false,
              lastResult: resultForMessage,
              minimum: _game.minimum,
              maximum: _game.maximum,
            );
          }
        } else if (correct) {
          final nextGame = _newGameWithAdaptiveTarget(_engine.newGame());
          _game = _engine.continueAfterCorrect(_game, nextGame);
          _botTeam.reset(_game.minimum, _game.maximum);
        }
      }
      if (isBot) {
        final feedback = switch (resultForMessage) {
          GuessResult.tooLow => BotFeedback.tooLow,
          GuessResult.tooHigh => BotFeedback.tooHigh,
          GuessResult.correct => BotFeedback.correct,
          GuessResult.outOfRange || null => null,
        };
        if (feedback != null) {
          _botTeam.observe(
            botId: botId,
            guess: guess,
            feedback: feedback,
            sharedMemory:
                (_progression.nebulaItems['bot_logic_upgrade'] ?? 0) > 0,
            nextRangeMinimum: _game.minimum,
            nextRangeMaximum: _game.maximum,
          );
        }
      }
      switch (resultForMessage) {
        case GuessResult.tooLow:
          _message = rangeScoutActive
              ? 'Range Scout narrowed the search to ${_game.minimum}–${_game.maximum}.'
              : _progression.legacySystems.activeMutators.contains('mut_blind')
              ? 'Guess recorded. Try again.'
              : isBot
              ? '$botId guessed $guess. Too low.'
              : 'Too low. Try a higher number!';
        case GuessResult.tooHigh:
          _message = rangeScoutActive
              ? 'Range Scout narrowed the search to ${_game.minimum}–${_game.maximum}.'
              : _progression.legacySystems.activeMutators.contains('mut_blind')
              ? 'Guess recorded. Try again.'
              : isBot
              ? '$botId guessed $guess. Too high.'
              : 'Too high. Try a lower number!';
        case GuessResult.correct:
          if (!isBot) _gamesWon++;
          _message = isBot
              ? '$botId guessed $guess correctly. A new round is ready.'
              : 'Correct! A new number is ready.';
        case GuessResult.outOfRange:
          _message =
              'Choose a number between ${_game.minimum} and ${_game.maximum}.';
        case null:
          break;
      }
    });
    if (!isBot) _controller.clear();
    await _persist();
  }

  Future<void> _newGame() async {
    setState(() {
      _game = _newGameWithAdaptiveTarget(_engine.newGame());
      _botTeam.reset(_game.minimum, _game.maximum);
      _message = 'Make your move.';
      _controller.clear();
    });
    await _persist();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoClickerTimer?.cancel();
    _playtimeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameDashboardPage(
      game: _game,
      progression: _progression,
      settings: _settings,
      activeSlot: _activeSlot,
      loading: _isLoading,
      message: _message,
      controller: _controller,
      onGuess: _submitGuess,
      onNewGame: _newGame,
      onUpgradeShop: _openUpgradeShop,
      onPrestige: _openProgressionHub,
      onArcade: _openArcade,
      onNebulaShop: _openNebulaShop,
      onWorldMap: _openWorldMap,
      onSaveSlots: _openSaveSlots,
      onSettings: _openSettings,
      onDeveloperSettings: _openDeveloperSettings,
      onLegacyPages: _openLegacyPages,
      onMusic: _openMusic,
      onLuckyStake: _openLuckyStake,
      onSystems: _openSystems,
      showDeveloperSettings: kDebugMode,
    );
  }
}
