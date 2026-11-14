import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'arcade/arcade_page.dart';
import 'core/automation/bot_team.dart';
import 'core/automation/guessing_bot.dart';
import 'core/automation/offline_earnings_settlement.dart';
import 'core/creative/creative_save_policy.dart';
import 'core/events/random_event_engine.dart';
import 'core/game/adaptive_target_generator.dart';
import 'core/game/difficulty_rules.dart';
import 'core/game/game_engine.dart';
import 'core/game/guess_economy_rules.dart';
import 'core/game/guess_rate_limit_policy.dart';
import 'core/legacy/invisible_trait_engine.dart';
import 'core/legacy/legacy_systems_engine.dart';
import 'core/liveops/live_ops_repository.dart';
import 'core/numbers/big_number.dart';
import 'core/progression/progression_calculator.dart';
import 'core/progression/progression_engine.dart';
import 'core/progression/progression_state.dart';
import 'core/scripting/lua_sandbox.dart';
import 'data/saves/save_data.dart';
import 'data/saves/save_storage.dart';
import 'dev/developer_settings_page.dart';
import 'home/game_dashboard_page.dart';
import 'i18n/app_localizations.dart';
import 'legacy/legacy_pages.dart';
import 'legacy/legacy_systems_page.dart';
import 'liveops/live_ops_page.dart';
import 'profile/player_profile_page.dart';
import 'progression/progression_hub_page.dart';
import 'saves/save_slots_page.dart';
import 'settings/game_settings.dart';
import 'settings/menu_studio_layout.dart';
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
              final brightness = settings.themeMode == 'System'
                  ? MediaQuery.platformBrightnessOf(context)
                  : settings.darkMode
                  ? Brightness.dark
                  : Brightness.light;
              final seedColor = Color(
                0xFF000000 |
                    int.parse(
                      settings.customPrimaryColor.substring(1),
                      radix: 16,
                    ),
              );
              return M3EMaterialApp(
                title: 'GuessTheNumber 2',
                data: brightness == Brightness.dark
                    ? M3EThemeData.dark(seedColor: seedColor)
                    : M3EThemeData.light(seedColor: seedColor),
                fontFamily: 'Manrope',
                autoTheming: false,
                dynamicColoring: false,
                initialTheme: brightness,
                themeAnimationDuration: Duration.zero,
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

  GameState _createGame() => _engineFor(_progression, _settings).newGame();

  GameState _newGameAfterCorrectGuess(
    GameState candidate,
    ProgressionState beforeGuess, {
    required int attempts,
  }) {
    var targetCandidate = candidate.secret;
    if (defaultTargetPlatform == TargetPlatform.android) {
      targetCandidate = AdaptiveTargetGenerator.nextTarget(
        rangeMin: candidate.minimum,
        rangeMax: candidate.maximum,
        difficultyId: _settings.difficultyId,
        streak: beforeGuess.currentStreak,
        attempts: attempts,
        seed: AdaptiveTargetGenerator.randomSeed(_adaptiveTargetSeedRandom),
      );
    }
    final secret = _invisibleTraitEngine.adjustNextTarget(
      profile: beforeGuess.legacySystems.adaptiveTraitProfile,
      candidate: targetCandidate,
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
  final Random _adaptiveTargetSeedRandom = Random.secure();
  final GuessRateLimiter _guessRateLimiter = GuessRateLimiter();
  final LuaSandbox _luaSandbox = const LuaSandbox();
  final RandomEventEngine _randomEventEngine = RandomEventEngine();
  Timer? _autoClickerTimer;
  Timer? _randomEventTimer;
  Timer? _randomEventBannerTimer;
  bool _randomEventRunning = false;
  String? _randomEventMessage;
  Timer? _playtimeTimer;
  BigNumber _lastIncomeMeasurement = BigNumber.fromInt(0);
  BigNumber _incomePerSecond = BigNumber.fromInt(0);
  bool _autoClickerTickRunning = false;
  bool _resumeCatchUpPending = false;
  ProgressionState _progression = ProgressionState.initial;
  final PlayerProfileStore _playerProfileStore = PlayerProfileStore();
  PlayerProfile _playerProfile = const PlayerProfile();
  GameSettings _settings = GameSettings.initial;
  final TextEditingController _controller = TextEditingController();
  late GameState _game = _createGame();
  late Future<SaveStorage> _storage = SaveStorage.inApplicationDocuments();
  int _activeSlot = 1;
  int _selectedPrimaryIndex = 2;
  final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();
  int _gamesWon = 0;
  bool _creativeModeEnabled = false;
  bool _isLoading = true;
  bool _isPlayerProfileLoaded = false;
  GameSettings? _menuStudioPreviewSettings;
  String _message = 'Make your move.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreSave().then((_) => _loadPlayerProfile()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeAutoClicker());
      _startPlaytimeTimer();
      _startRandomEventTimer();
    } else {
      _autoClickerTimer?.cancel();
      _autoClickerTimer = null;
      _playtimeTimer?.cancel();
      _playtimeTimer = null;
      _randomEventTimer?.cancel();
      _randomEventTimer = null;
    }
  }

  void _startPlaytimeTimer() {
    if (!mounted || _isLoading || _playtimeTimer?.isActive == true) return;
    _lastIncomeMeasurement = _progression.money;
    _incomePerSecond = BigNumber.fromInt(0);
    _playtimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isLoading) return;
      final currentMoney = _progression.money;
      final income = _progression.legacySystems.autoClickerActive
          ? currentMoney - _lastIncomeMeasurement
          : BigNumber.fromInt(0);
      _lastIncomeMeasurement = currentMoney;
      final next = _progression.copyWith(
        playtimeSeconds: _progression.playtimeSeconds + 1,
      );
      final evaluated = _progressionEngine.evaluateAchievements(next);
      final unlocked =
          evaluated.achievements.length > _progression.achievements.length;
      setState(() {
        _progression = evaluated;
        _incomePerSecond = income;
      });
      if (unlocked || evaluated.playtimeSeconds % 30 == 0) {
        unawaited(_persist());
      }
    });
  }

  void _startRandomEventTimer() {
    if (!mounted ||
        _isLoading ||
        _randomEventTimer?.isActive == true ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.detached) {
      return;
    }
    _randomEventTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_runRandomEventTick());
    });
  }

  Future<void> _runRandomEventTick() async {
    if (!mounted || _isLoading || _randomEventRunning) return;
    _randomEventRunning = true;
    try {
      final manifest = jsonDecode(
        await rootBundle.loadString('assets/scripts/manifest.json'),
      );
      if (manifest is! Map<String, dynamic> ||
          manifest['schemaVersion'] != 1 ||
          manifest['hostApiVersion'] != 1 ||
          manifest['scripts'] is! List) {
        throw const FormatException('Invalid Lua script manifest.');
      }
      String? scriptPath;
      for (final entry in manifest['scripts'] as List) {
        if (entry is Map && entry['id'] == 'random_event') {
          final file = entry['file'];
          if (file is String &&
              file.endsWith('.lua') &&
              !file.startsWith('/') &&
              !file.contains('..')) {
            scriptPath = 'assets/scripts/$file';
          }
          break;
        }
      }
      if (scriptPath == null) {
        throw const FormatException('Random-event script is not registered.');
      }
      final source = await rootBundle.loadString(scriptPath);
      final execution = await _luaSandbox.execute(
        scriptId: 'random_event',
        source: source,
      );
      final output = execution.value;
      if (output is! Map ||
          output['trigger'] != true ||
          output['type'] is! String) {
        return;
      }
      final eventType = randomEventTypeFromLuaId(output['type'] as String);
      if (eventType == null) return;
      final result = _randomEventEngine.apply(
        progression: _progression,
        game: _game,
        type: eventType,
      );
      final message = switch (eventType) {
        RandomEventType.cashBurst => 'Cash Burst · bonus Money added',
        RandomEventType.nebulaRain => 'Nebula Rain · 10–50 Nebula added',
        RandomEventType.jackpot => 'Jackpot · 1,000× your range in Money',
        RandomEventType.streakSurge => 'Streak Surge · +2 streak',
        RandomEventType.rangeShuffle => 'Range Shuffle · secret number changed',
        RandomEventType.taxRefund => 'Tax Refund · Money returned',
        RandomEventType.cosmicGift => 'Cosmic Gift · +100 Nebula',
      };
      if (!mounted) return;
      setState(() {
        _progression = result.progression;
        _game = result.game;
        _randomEventMessage = message;
      });
      _randomEventBannerTimer?.cancel();
      _randomEventBannerTimer = Timer(const Duration(seconds: 8), () {
        if (!mounted) return;
        setState(() {
          _randomEventMessage = null;
          _progression = _progression.copyWith(clearLastRandomEventId: true);
        });
        unawaited(_persist());
      });
      await _persist();
    } catch (error) {
      debugPrint('Random-event selector failed safely: $error');
    } finally {
      _randomEventRunning = false;
    }
  }

  Future<void> _resumeAutoClicker() async {
    if (!mounted || _isLoading) return;
    if (_autoClickerTickRunning) {
      _resumeCatchUpPending = true;
      return;
    }
    final settlement = OfflineEarningsSettlement.settle(
      progression: _progression,
      nowMillis: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() {
      _progression = settlement.progression;
      if (settlement.clockRollbackDetected) {
        _message = 'Clock rollback detected. Auto Clicker paused for 24 hours.';
      } else if (settlement.earnings.compareTo(BigNumber.fromInt(0)) > 0) {
        _message =
            'Auto Clicker earned ${settlement.earnings} Money while the app was away.';
      }
    });
    await _persist();
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
        final settlement = OfflineEarningsSettlement.settle(
          progression: restoredProgression,
          nowMillis: DateTime.now().millisecondsSinceEpoch,
        );
        restoredProgression = settlement.progression;
        final timeTravelDetected = settlement.clockRollbackDetected;
        final offlineEarnings = settlement.earnings;
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
          _creativeModeEnabled = save.creativeModeEnabled;
          _progression = restoredProgression;
          _settings = restoredSettings;
          _selectedPrimaryIndex =
              MenuStudioLayout.fromSettings(restoredSettings)
                  .primaryNavigationIds
                  .where((id) => id != 'dev_settings' || kDebugMode)
                  .toList()
                  .indexOf('play');
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
        _startRandomEventTimer();
      }
    }
    _botTeam.reset(_game.minimum, _game.maximum);
    if (shouldPersistOfflineEarnings) await _persist();
    _scheduleAutoClicker();
  }

  Future<void> _persist({bool evaluateAchievements = true}) async {
    if (evaluateAchievements) {
      final evaluated = _progressionEngine.evaluateAchievements(_progression);
      if (evaluated != _progression) {
        _progression = evaluated;
        if (mounted) setState(() {});
      }
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
              creativeModeEnabled: _creativeModeEnabled,
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
          creativeModeEnabled: _creativeModeEnabled,
        );
      });
    } on Exception {
      if (mounted) {
        setState(() => _message = 'Game is still playable, but saving failed.');
      }
    }
  }

  Future<bool> _updateCreativeRange(int minimum, int maximum) async {
    if (!_creativeModeEnabled) return false;
    final updated = CreativeSavePolicy.updateRange(
      current: _currentSaveData(),
      minimum: minimum,
      maximum: maximum,
    );
    if (updated == null) return false;

    final nextGame = _engine.restore(
      secret: updated.secret,
      attempts: updated.attempts,
      isComplete: updated.isComplete,
      savedMinimum: updated.minimum,
      savedMaximum: updated.maximum,
    );
    setState(() {
      _game = nextGame;
      _progression = updated.progression;
      _controller.clear();
      _message = 'Creative Save range updated. A fresh round is ready.';
    });
    _botTeam.reset(minimum, maximum);
    await _persist(evaluateAchievements: false);
    return true;
  }

  Future<bool> _updateCreativeValue(String key, String value) async {
    if (!_creativeModeEnabled) return false;
    final updated = CreativeSavePolicy.updateValue(
      current: _currentSaveData(),
      key: key,
      value: value,
      upgrades: UpgradeCatalog.all,
      prestigeUpgrades: UpgradeCatalog.prestige,
      ultraUpgrades: UpgradeCatalog.ultra,
    );
    if (updated == null) return false;

    setState(() {
      _progression = updated.progression;
      if (key == 'attempts') {
        _game = GameState(
          secret: _game.secret,
          attempts: updated.attempts,
          isComplete: _game.isComplete,
          lastResult: _game.lastResult,
          minimum: _game.minimum,
          maximum: _game.maximum,
        );
      }
      _message = 'Creative Save updated.';
    });
    await _persist(evaluateAchievements: false);
    return true;
  }

  Future<ProgressionState> _purchaseUpgrade(
    UpgradeDefinition definition, {
    int levels = 1,
  }) async {
    final updated = _progressionEngine.purchaseUpgradeLevels(
      _progression,
      definition,
      levels: levels,
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
          _game = _engine.newGame();
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
        _game = _engine.newGame();
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
        _game = _engine.newGame();
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

  Future<T?> _pushShellRoute<T>(Route<T> route) async {
    final navigator = _shellNavigatorKey.currentState!;
    final originIndex = _selectedPrimaryIndex;
    final result = await navigator.push<T>(route);
    if (mounted) {
      if (originIndex == 4) {
        navigator.popUntil((route) => route.isFirst);
      }
      _onPrimarySelected(2);
    }
    return result;
  }

  Future<void> _openProgressionHub({bool ultra = false}) async {
    await _pushShellRoute<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProgressionHubPage(
          progression: _progression,
          initialUltra: ultra,
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
    await _pushShellRoute<void>(
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

  Future<ProgressionState> _equipNebulaCosmetic(String cosmeticId) async {
    final updated = _progressionEngine.equipNebulaCosmetic(
      _progression,
      cosmeticId,
    );
    if (updated != _progression) {
      setState(() => _progression = updated);
      await _persist();
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
        _game = _engine.newGame();
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
    await _pushShellRoute<void>(
      MaterialPageRoute<void>(
        builder: (_) => NebulaShopPage(
          progression: _progression,
          onPurchase: _purchaseNebulaItem,
          onAutomationChanged: _setAutomationActive,
          onEquipCosmetic: _equipNebulaCosmetic,
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
    await _pushShellRoute<void>(
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
      final settlement = OfflineEarningsSettlement.settle(
        progression: nextProgression,
        nowMillis: DateTime.now().millisecondsSinceEpoch,
      );
      nextProgression = settlement.progression;
      final timeTravelDetected = settlement.clockRollbackDetected;
      final offlineEarnings = settlement.earnings;

      // Slot changes must run the same legacy music migration as startup.
      // Otherwise a slot with settings-backed music can appear empty until
      // the next full app restart, and the two persisted representations drift.
      final savedSettings = save?.settings ?? GameSettings.initial;
      final restoredMusicSystems = restoreMusicStateFromSettings(
        settings: savedSettings,
        systems: nextProgression.legacySystems,
      );
      nextProgression = nextProgression.copyWith(
        legacySystems: restoredMusicSystems,
      );
      final nextSettings = syncMusicSettingsFromLegacy(
        settings: savedSettings,
        systems: restoredMusicSystems,
      );
      await AppLocalizations.load(nextSettings.localeCode);
      await storage.saveActiveSlot(slot);
      if (!mounted) return;
      final nextEngine = _engineFor(nextProgression, nextSettings);
      setState(() {
        _storage = Future.value(storage);
        _activeSlot = slot;
        _engine = nextEngine;
        _game = save == null
            ? _engine.newGame()
            : _engine.restore(
                secret: save.secret,
                attempts: save.attempts,
                isComplete: save.isComplete,
                savedMinimum: save.minimum,
                savedMaximum: save.maximum,
              );
        _gamesWon = save?.gamesWon ?? 0;
        _creativeModeEnabled = save?.creativeModeEnabled ?? false;
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

  Future<void> _loadPlayerProfile() async {
    try {
      var profile = await _playerProfileStore.load();
      if (profile.username.isEmpty) {
        final savedGame = await (await _storage).load();
        if (savedGame != null && savedGame.profileName.isNotEmpty) {
          profile = PlayerProfile(
            username: savedGame.profileName.length > 20
                ? savedGame.profileName.substring(0, 20)
                : savedGame.profileName,
            avatarId: switch (savedGame.profileIconId) {
              'bolt' => 'lightning',
              'crown' => 'crown',
              'planet' => 'moon',
              _ => 'star',
            },
            profileId: PlayerProfile.generateId(),
            setupComplete: true,
          );
          profile = await _playerProfileStore.save(profile);
        }
      }
      if (mounted) {
        setState(() {
          _playerProfile = profile;
          _isPlayerProfileLoaded = true;
        });
      }
    } on Exception {
      // A missing or unreadable profile never blocks loading the game.
      if (mounted) setState(() => _isPlayerProfileLoaded = true);
    }
  }

  Future<void> _syncPlayerProfileToSave(PlayerProfile profile) async {
    final legacyIconId = switch (profile.avatarId) {
      'lightning' => 'bolt',
      'crown' => 'crown',
      'moon' => 'planet',
      'star' => 'star',
      _ => 'default',
    };
    try {
      final storage = await _storage;
      final current = await storage.load();
      if (current == null) return;
      await storage.update((existing) {
        final base = existing ?? current;
        return base.copyWith(
          profileName: profile.username,
          profileIconId: legacyIconId,
        );
      });
    } on Exception {
      if (mounted) {
        setState(
          () => _message = 'Profile saved, but save-slot metadata could not be synchronized.',
        );
      }
    }
  }

  Future<void> _openPlayerProfile() async {
    await _pushShellRoute<void>(
      MaterialPageRoute<void>(
        builder: (_) => PlayerProfilePage(
          initialProfile: _playerProfile,
          store: _playerProfileStore,
          equippedCosmeticId: _progression.equippedCosmeticId,
          onSaved: (profile) {
            setState(() => _playerProfile = profile);
            unawaited(_syncPlayerProfileToSave(profile));
          },
        ),
      ),
    );
  }

  Future<void> _resetEverything() async {
    for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++) {
      final storage = await SaveStorage.inApplicationDocuments(slot: slot);
      await storage.reset();
    }
    final firstSlot = await SaveStorage.inApplicationDocuments(slot: 1);
    await firstSlot.saveActiveSlot(1);
    if (!mounted) return;
    setState(() {
      _activeSlot = 1;
      _storage = Future.value(firstSlot);
      _progression = ProgressionState.initial;
      _engine = _engineFor(_progression, _settings);
      _game = _engine.newGame();
      _gamesWon = 0;
      _creativeModeEnabled = false;
      _controller.clear();
      _botTeam.reset(_game.minimum, _game.maximum);
      _message = 'All game data has been reset.';
    });
  }

  Future<void> _openSaveSlots() async {
    await _pushShellRoute<void>(
      MaterialPageRoute<void>(
        builder: (_) => SaveSlotsPage(
          activeSlot: _activeSlot,
          onSelect: _switchSaveSlot,
          onResetEverything: _resetEverything,
        ),
      ),
    );
  }

  Future<void> _updateSettings(GameSettings settings) async {
    await AppLocalizations.load(settings.localeCode);
    if (!mounted) return;
    final difficultyChanged = settings.difficultyId != _settings.difficultyId;
    final menuLayoutChanged =
        settings.webMenuStudioLayout != _settings.webMenuStudioLayout ||
        settings.moreScreenOrder.join('|') !=
            _settings.moreScreenOrder.join('|');
    final currentNavigation = MenuStudioLayout.fromSettings(_settings)
        .primaryNavigationIds
        .where((id) => id != 'dev_settings' || kDebugMode)
        .toList();
    final selectedDestination =
        _selectedPrimaryIndex >= 0 &&
            _selectedPrimaryIndex < currentNavigation.length
        ? currentNavigation[_selectedPrimaryIndex]
        : 'play';
    final nextNavigation = MenuStudioLayout.fromSettings(settings)
        .primaryNavigationIds
        .where((id) => id != 'dev_settings' || kDebugMode)
        .toList();
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
      _menuStudioPreviewSettings = null;
      if (menuLayoutChanged) {
        final nextIndex = nextNavigation.indexOf(selectedDestination);
        _selectedPrimaryIndex = nextIndex >= 0
            ? nextIndex
            : MenuStudioLayout.fromSettings(synchronizedSettings)
                  .primaryNavigationIds
                  .where((id) => id != 'dev_settings' || kDebugMode)
                  .toList()
                  .indexOf('play');
      }
      if (difficultyChanged) {
        _engine = _engineFor(nextProgression, synchronizedSettings);
        _game = _engine.newGame();
        _botTeam.reset(_game.minimum, _game.maximum);
        _message =
            'Difficulty changed to ${DifficultyRules.name(settings.difficultyId)}. A fresh round is ready.';
      }
    });
    GtnApp.settingsNotifier.value = synchronizedSettings;
    await _persist();
  }

  void _onPrimarySelected(int index) {
    setState(() => _selectedPrimaryIndex = index);
  }

  Future<void> _showNimmyTutorial() async {
    var step = 0;
    const steps = <({String title, String body})>[
      (
        title: 'Welcome to Guess The Number',
        body: 'Find the hidden number. Use the current range and feedback to narrow it down.',
      ),
      (
        title: 'Make a guess',
        body: 'Enter a number and press GUESS. A low or high result helps you narrow the range.',
      ),
      (
        title: 'Use quick picks',
        body: 'LOW END, MIDPOINT and HIGH END fill the guess field. CLEAR empties it.',
      ),
      (
        title: 'Grow your run',
        body: 'Earn Money, unlock upgrades and explore Arcade, Beyond the Numbers and More.',
      ),
    ];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Nimmy · ${steps[step].title}'),
          content: Text(steps[step].body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                if (step == steps.length - 1) {
                  Navigator.pop(dialogContext);
                } else {
                  update(() => step++);
                }
              },
              child: Text(step == steps.length - 1 ? 'Finish' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await _pushShellRoute<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          settings: _settings,
          onChanged: _updateSettings,
          onOpenMenuStudio: _openMenuStudio,
          onReplayTutorial: _showNimmyTutorial,
        ),
      ),
    );
  }

  Future<void> _openMenuStudio() async {
    await _pushShellRoute<void>(
      MaterialPageRoute<void>(
        builder: (_) => MenuStudioPage(
          settings: _settings,
          onChanged: _updateSettings,
          onPreview: (settings) {
            if (mounted) {
              setState(() => _menuStudioPreviewSettings = settings);
              GtnApp.settingsNotifier.value = settings;
            }
          },
          onCancel: () {
            if (mounted) {
              setState(() => _menuStudioPreviewSettings = null);
              GtnApp.settingsNotifier.value = _settings;
            }
          },
        ),
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
    creativeModeEnabled: _creativeModeEnabled,
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
      _creativeModeEnabled = save.creativeModeEnabled;
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
        _game = _engine.newGame();
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
    await _pushShellRoute<void>(
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
        _game = _engine.newGame();
        _botTeam.reset(_game.minimum, _game.maximum);
        _message = 'Hardcore range changed. A fresh round is ready.';
      }
    });
    await _persist();
    _scheduleAutoClicker();
  }

  Future<ProgressionState?> _claimLiveOpsReward(LiveOpsEvent event) async {
    final result = _legacySystemsEngine.claimLiveOpsReward(
      progression: _progression,
      systems: _progression.legacySystems,
      event: event.toClaimDefinition(),
    );
    if (!result.accepted) {
      if (mounted) setState(() => _message = result.message);
      return null;
    }
    await _applyLegacyProgression(
      result.progression.copyWith(legacySystems: result.systems),
    );
    return _progression;
  }

  Future<void> _openLiveOps() async {
    await _pushShellRoute<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveOpsPage(
          progression: _progression,
          onClaim: _claimLiveOpsReward,
        ),
      ),
    );
  }

  Future<void> _openLegacyPages() async {
    await _pushShellRoute<void>(
      MaterialPageRoute<void>(
        builder: (_) => LegacyHubPage(
          progression: _progression,
          activeSlot: _activeSlot,
          onSystemsChanged: _applyLegacyProgression,
          onOpenProfile: _openPlayerProfile,
          onOpenSaveSlots: _openSaveSlots,
          onOpenSettings: _openSettings,
          onOpenDeveloperSettings: kDebugMode ? _openDeveloperSettings : null,
          onOpenShop: _openNebulaShop,
          onOpenProgression: _openProgressionHub,
        ),
      ),
    );
    _scheduleAutoClicker();
  }

  Future<void> _openLegacySection(LegacySection section) async {
    await _pushShellRoute<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            LegacyDetailPage(section: section, progression: _progression),
      ),
    );
  }

  Future<void> _openLegacySystems(LegacySystemsView view) async {
    await _pushShellRoute<void>(
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
    await _pushShellRoute<void>(
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
    if (!isBot && !_guessRateLimiter.tryAccept()) {
      setState(
        () => _message = AppLocalizations.text(
          'guess_rate_limited',
          'Please wait a moment before guessing again.',
        ),
      );
      return;
    }
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
        // GTN1 observes the guess before trait resolution. Adaptive helper
        // eligibility therefore uses the pre-guess streak, while the profile
        // observation still records the streak produced by this guess.
        final expectedNewStreak = isBot
            ? beforeGuess.currentStreak
            : correct
            ? beforeGuess.currentStreak + 1
            : 0;
        final adaptiveProfileForDecision = _invisibleTraitEngine.observeGuess(
          profile: legacySystems.adaptiveTraitProfile,
          correct: correct,
          newStreak: expectedNewStreak,
          reward: BigNumber.fromInt(0),
        );
        final adaptiveDecision = _invisibleTraitEngine.evaluate(
          profile: adaptiveProfileForDecision,
          prestigeCount:
              adaptiveProfileForDecision.prestigesObserved >
                  beforeGuess.prestigeResets
              ? adaptiveProfileForDecision.prestigesObserved
              : beforeGuess.prestigeResets,
          ultraCount:
              adaptiveProfileForDecision.ultrasObserved >
                  beforeGuess.ultraResets
              ? adaptiveProfileForDecision.ultrasObserved
              : beforeGuess.ultraResets,
          currentStreak: beforeGuess.currentStreak,
        );
        final combinedTraitMultiplier = _invisibleTraitEngine
            .combinedRewardMultiplier(
              gameplayTraitMultiplier: traitEffects.correctGuessMultiplier,
              helperIds: adaptiveDecision.helperIds,
              bonusCount: adaptiveDecision.bonusIds.length,
            );

        BigNumber calculateCorrectGuessReward(
          double traitMultiplier,
        ) => GuessEconomyRules.correctGuessReward(
          rangeMaximum: _game.maximum,
          currentStreak: beforeGuess.currentStreak,
          rewardMultiplierLevel: beforeGuess.upgrades['reward_multiplier'] ?? 0,
          // talent_reward_1 is a Prestige talent, not the legacy shop/upgrade flag
          // consumed by GameEngine's base reward calculation. GTN1 applies its
          // +50% once in applyTalentBonuses after the raw reward is recorded.
          hasTalentReward: false,
          isCritical: isCritical,
          difficultyId: _settings.difficultyId,
          mutatorMultiplier: _legacySystemsEngine.mutatorRewardMultiplier(
            legacySystems,
          ),
          traitMultiplier: BigNumber.parse(traitMultiplier.toStringAsFixed(2)),
          permanentMoneyMultiplier: GuessEconomyRules.moneyEarningMultiplier(
            beforeGuess,
          ),
        );

        // Keep the unmodified base reward for the adaptive profile, matching
        // GTN1's observation before TraitGameplayRules applies its combined
        // gameplay-trait and adaptive multiplier.
        final baseRewardForAdaptiveProfile = correct
            ? calculateCorrectGuessReward(1.0)
            : BigNumber.fromInt(0);
        final rawReward = correct
            ? calculateCorrectGuessReward(combinedTraitMultiplier)
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
          reward: baseRewardForAdaptiveProfile,
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
            final nextGame = _newGameAfterCorrectGuess(
              _engine.newGame(),
              beforeGuess,
              attempts: previousAttempts,
            );
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
          final nextGame = _newGameAfterCorrectGuess(
            _engine.newGame(),
            beforeGuess,
            attempts: previousAttempts,
          );
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
      _game = _engine.newGame();
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
    _randomEventTimer?.cancel();
    _randomEventBannerTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPlayerProfileLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_playerProfile.setupComplete) {
      return PlayerProfilePage(
        firstLaunch: true,
        viewOnly: false,
        initialProfile: _playerProfile,
        store: _playerProfileStore,
        equippedCosmeticId: _progression.equippedCosmeticId,
        onSaved: (profile) {
          setState(() => _playerProfile = profile);
          unawaited(_syncPlayerProfileToSave(profile));
        },
      );
    }
    return GameDashboardPage(
      game: _game,
      progression: _progression,
      incomePerSecond: _incomePerSecond,
      settings: _menuStudioPreviewSettings ?? _settings,
      settingsListenable: GtnApp.settingsNotifier,
      activeSlot: _activeSlot,
      loading: _isLoading,
      message: _message,
      randomEventMessage: _randomEventMessage,
      controller: _controller,
      onGuess: _submitGuess,
      onNewGame: _newGame,
      onUpgradeShop: _openUpgradeShop,
      onPrestige: _openProgressionHub,
      onUltra: () => _openProgressionHub(ultra: true),
      onArcade: _openArcade,
      onNebulaShop: _openNebulaShop,
      onWorldMap: _openWorldMap,
      onSaveSlots: _openSaveSlots,
      onSettings: _openSettings,
      onDeveloperSettings: _openDeveloperSettings,
      onLegacyPages: _openLegacyPages,
      onLiveOps: _openLiveOps,
      onMusic: _openMusic,
      onLuckyStake: _openLuckyStake,
      onSystems: _openSystems,
      showDeveloperSettings: kDebugMode,
      shellNavigatorKey: _shellNavigatorKey,
      selectedIndex: _selectedPrimaryIndex,
      onPrimarySelected: _onPrimarySelected,
      onSystemsView: _openLegacySystems,
      onLegacySection: _openLegacySection,
      playerProfile: _playerProfile,
      onPlayerProfile: _openPlayerProfile,
      creativeModeEnabled: _creativeModeEnabled,
      onCreativeRange: _updateCreativeRange,
      onCreativeValue: _updateCreativeValue,
    );
  }
}
