import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'arcade/arcade_page.dart';
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
import 'progression/progression_hub_page.dart';
import 'saves/save_slots_page.dart';
import 'settings/game_settings.dart';
import 'settings/settings_page.dart';
import 'shop/nebula_shop_page.dart';
import 'shop/upgrade_catalog.dart';
import 'shop/upgrade_shop_page.dart';
import 'worlds/world_boss_catalog.dart';
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
      builder: (context, translations, _) => ValueListenableBuilder<GameSettings>(
      valueListenable: settingsNotifier,
      builder: (context, settings, _) {
        ThemeData makeTheme(Brightness brightness) => ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF7C5CFC),
                brightness: brightness,
              ),
              useMaterial3: true,
              fontFamily: 'Manrope',
            );
        return MaterialApp(
          title: 'GuessTheNumber 2',
          debugShowCheckedModeBanner: false,
          theme: makeTheme(Brightness.light),
          darkTheme: makeTheme(Brightness.dark),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: settings.reduceMotion,
            ),
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

class _GameHomePageState extends State<GameHomePage> {
  GameEngine _engine = GameEngine();

  int _rangeMaximum(ProgressionState progression, GameSettings settings) =>
      DifficultyRules.rangeMaximum(
        settings.difficultyId,
        progression.upgrades['better_range'] ?? 0,
      ) * _legacySystemsEngine.rangeMultiplier(progression.legacySystems);

  GameEngine _engineFor(ProgressionState progression, GameSettings settings) =>
      GameEngine(maximum: _rangeMaximum(progression, settings));

  GameState _createGame() => _newGameWithAdaptiveTarget(
        _engineFor(_progression, _settings).newGame(),
      );

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
  final LegacySystemsEngine _legacySystemsEngine = const LegacySystemsEngine();
  final InvisibleTraitEngine _invisibleTraitEngine = const InvisibleTraitEngine();
  ProgressionState _progression = ProgressionState.initial;
  GameSettings _settings = GameSettings.initial;
  final TextEditingController _controller = TextEditingController();
  late GameState _game = _createGame();
  late Future<SaveStorage> _storage = SaveStorage.inApplicationDocuments();
  int _activeSlot = 1;
  int _gamesWon = 0;
  bool _isLoading = true;
  String _message = 'Guess a number between 1 and 100.';

  @override
  void initState() {
    super.initState();
    _restoreSave();
  }

  Future<void> _restoreSave() async {
    try {
      final storage = await _storage;
      final save = await storage.load();
      if (!mounted) return;
      if (save != null) {
        final restoredProgression = save.progression;
        final restoredEngine = _engineFor(restoredProgression, save.settings);
        await AppLocalizations.load(save.settings.localeCode);
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
          _settings = save.settings;
          GtnApp.settingsNotifier.value = _settings;
          _message = 'Welcome back! Your saved game is ready.';
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _message = 'A new game is ready. Your save could not be loaded.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _persist() async {
    try {
      final storage = await _storage;
      await storage.save(
        SaveData(
          secret: _game.secret,
          attempts: _game.attempts,
          gamesWon: _gamesWon,
          isComplete: _game.isComplete,
          minimum: _game.minimum,
          maximum: _game.maximum,
          progression: _progression,
          settings: _settings,
        ),
      );
    } on Exception {
      if (mounted) {
        setState(() => _message = 'Game is still playable, but saving failed.');
      }
    }
  }

  Future<ProgressionState> _purchaseUpgrade(
    UpgradeDefinition definition,
  ) async {
    final updated = _progressionEngine.purchaseUpgrade(_progression, definition);
    if (updated != _progression) {
      final previousRange = _rangeMaximum(_progression, _settings);
      final nextRange = _rangeMaximum(updated, _settings);
      final withQuestProgress = updated.copyWith(
        legacySystems: _legacySystemsEngine.recordUpgradePurchase(
          updated.legacySystems,
        ).copyWith(
          adaptiveTraitProfile: _invisibleTraitEngine.observeUpgradePurchase(
            updated.legacySystems.adaptiveTraitProfile,
          ),
        ),
      );
      setState(() {
        _progression = withQuestProgress;
        if (previousRange != nextRange) {
          _engine = _engineFor(withQuestProgress, _settings);
          _game = _newGameWithAdaptiveTarget(_engine.newGame());
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
        prestigeDelta: updated.prestigeResets > existingProfile.prestigesObserved
            ? updated.prestigeResets - existingProfile.prestigesObserved
            : 0,
        ultraDelta: updated.ultraResets > existingProfile.ultrasObserved
            ? updated.ultraResets - existingProfile.ultrasObserved
            : 0,
      );
      updated = updated.copyWith(
        legacySystems: updated.legacySystems.copyWith(adaptiveTraitProfile: profile),
      );
      setState(() {
        _progression = updated;
        _engine = _engineFor(updated, _settings);
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
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
        prestigeDelta: _progression.prestigeResets > existingProfile.prestigesObserved
            ? _progression.prestigeResets - existingProfile.prestigesObserved
            : 0,
        ultraDelta: updated.ultraResets > existingProfile.ultrasObserved
            ? updated.ultraResets - existingProfile.ultrasObserved
            : 0,
      );
      updated = updated.copyWith(
        legacySystems: updated.legacySystems.copyWith(adaptiveTraitProfile: profile),
      );
      setState(() {
        _progression = updated;
        _engine = _engineFor(updated, _settings);
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
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


  Future<void> _awardArcadeReward(
    BigNumber nebula,
    BigNumber money,
  ) async {
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


  Future<ProgressionState> _purchaseNebulaItem(
    NebulaShopItem item,
  ) async {
    final updated = _progressionEngine.purchaseNebulaItem(
      _progression,
      itemId: item.id,
      price: item.price,
    );
    if (updated != _progression) {
      setState(() => _progression = updated);
      await _persist();
    }
    return _progression;
  }

  Future<void> _openNebulaShop() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NebulaShopPage(
          progression: _progression,
          onPurchase: _purchaseNebulaItem,
        ),
      ),
    );
  }


  Future<ProgressionState> _attackWorldBoss(
    WorldBossDefinition boss,
  ) async {
    final updated = _progressionEngine.attackWorldBoss(_progression, boss);
    if (updated != _progression) {
      setState(() => _progression = updated);
      await _persist();
    }
    return _progression;
  }

  Future<void> _openWorldMap() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WorldMapPage(
          progression: _progression,
          onAttack: _attackWorldBoss,
        ),
      ),
    );
  }


  Future<void> _switchSaveSlot(int slot) async {
    setState(() => _isLoading = true);
    try {
      final storage = await SaveStorage.inApplicationDocuments(slot: slot);
      final save = await storage.load();
      if (!mounted) return;
      final nextProgression = save?.progression ?? ProgressionState.initial;
      await AppLocalizations.load(save?.settings.localeCode ?? 'en_us');
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
        _message = save == null
            ? 'New save slot ready. Guess a number between 1 and 100.'
            : 'Save slot $slot loaded.';
        _isLoading = false;
      });
      if (save == null) await _persist();
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
        builder: (_) => SaveSlotsPage(
          activeSlot: _activeSlot,
          onSelect: _switchSaveSlot,
        ),
      ),
    );
  }


  Future<void> _updateSettings(GameSettings settings) async {
    await AppLocalizations.load(settings.localeCode);
    if (!mounted) return;
    final difficultyChanged = settings.difficultyId != _settings.difficultyId;
    setState(() {
      _settings = settings;
      if (difficultyChanged) {
        _engine = _engineFor(_progression, settings);
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
        _message = 'Difficulty changed to ${DifficultyRules.name(settings.difficultyId)}. A fresh round is ready.';
      }
    });
    GtnApp.settingsNotifier.value = settings;
    await _persist();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          settings: _settings,
          onChanged: _updateSettings,
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
      );

  Future<void> _applyDeveloperSave(SaveData save) async {
    setState(() {
      _game = _engine.restore(
        secret: save.secret,
        attempts: save.attempts,
        isComplete: save.isComplete,
        savedMinimum: save.minimum,
        savedMaximum: save.maximum,
      );
      _gamesWon = save.gamesWon;
      _progression = save.progression;
      _settings = save.settings;
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
      setState(() {
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
        _progression = ProgressionState.initial;
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
    final oldRange = _rangeMaximum(_progression, _settings);
    final newRange = _rangeMaximum(progression, _settings);
    setState(() {
      _progression = progression;
      if (oldRange != newRange) {
        _engine = _engineFor(progression, _settings);
        _game = _newGameWithAdaptiveTarget(_engine.newGame());
        _message = 'Hardcore range changed. A fresh round is ready.';
      }
    });
    await _persist();
  }

  Future<void> _openLegacyPages() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LegacyHubPage(
          progression: _progression,
          onSystemsChanged: _applyLegacyProgression,
        ),
      ),
    );
  }

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

  Future<void> _submitGuess() async {
    final guess = int.tryParse(_controller.text.trim());
    if (guess == null) {
      setState(() => _message = 'Enter a whole number from ${_game.minimum} to ${_game.maximum}.');
      return;
    }

    setState(() {
      var rangeScoutActive = false;
      final previousAttempts = _game.attempts;
      _game = _engine.guess(_game, guess);
      if (_game.attempts > previousAttempts) {
        final correct = _game.lastResult == GuessResult.correct;
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
            (beforeGuess.nebulaItems['golden_guess'] ?? 0) > 0 &&
            (beforeGuess.totalGuesses + 1) % 10 == 0;
        final isCritical = correct &&
            (guaranteedGoldenGuess ||
                Random.secure().nextDouble() <
                    GuessEconomyRules.criticalChance(criticalPrecisionLevel));
        final rawReward = correct
            ? GuessEconomyRules.correctGuessReward(
                rangeMaximum: _game.maximum,
                currentStreak: beforeGuess.currentStreak,
                rewardMultiplierLevel:
                    beforeGuess.upgrades['reward_multiplier'] ?? 0,
                hasTalentReward: legacySystems.talents.contains('talent_reward_1'),
                isCritical: isCritical,
                difficultyId: _settings.difficultyId,
                mutatorMultiplier:
                    _legacySystemsEngine.mutatorRewardMultiplier(legacySystems),
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
          prestigeCount: adaptiveProfile.prestigesObserved > beforeGuess.prestigeResets
              ? adaptiveProfile.prestigesObserved
              : beforeGuess.prestigeResets,
          ultraCount: adaptiveProfile.ultrasObserved > beforeGuess.ultraResets
              ? adaptiveProfile.ultrasObserved
              : beforeGuess.ultraResets,
          currentStreak: afterReward.currentStreak,
        );
        rangeScoutActive = rangeScoutActive ||
            adaptiveDecision.helperIds.contains(InvisibleTraitEngine.helperRangeScout);
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
            crystalCoreProc: legacySystems.equippedRelics.contains('crystal_golem') &&
                Random.secure().nextDouble() < 0.10,
            nebulaBoostOwned: (beforeGuess.nebulaItems['nebula_boost'] ?? 0) > 0,
          );
          final adaptiveBonusRate = (
            (adaptiveDecision.helperIds.contains(InvisibleTraitEngine.helperComeback) ? 0.05 : 0.0) +
            (adaptiveDecision.helperIds.contains(InvisibleTraitEngine.helperMomentum) ? 0.03 : 0.0) +
            adaptiveDecision.bonusIds.length * 0.10
          ).clamp(0.0, 0.30).toDouble();
          if (adaptiveBonusRate > 0) {
            final earned = afterReward.money - beforeGuess.money;
            final adaptiveBonus = earned * BigNumber.parse(adaptiveBonusRate.toStringAsFixed(2));
            afterReward = afterReward.copyWith(
              money: afterReward.money + adaptiveBonus,
              moneyEarned: afterReward.moneyEarned + adaptiveBonus,
            );
          }
        } else {
          final difficultyPenalty = beforeGuess.money *
              BigNumber.parse(DifficultyRules.wrongGuessPenalty(_settings.difficultyId).toStringAsFixed(2));
          final taxPenalty = legacySystems.activeMutators.contains('mut_tax')
              ? beforeGuess.money * BigNumber.parse('0.05')
              : BigNumber.fromInt(0);
          final penalty = difficultyPenalty + taxPenalty;
          final refund = penalty * BigNumber.parse(
            traitEffects.missPenaltyRefundRate.toStringAsFixed(2),
          );
          final adaptiveRefund = adaptiveDecision.helperIds.contains(
            InvisibleTraitEngine.helperMistakeInsurance,
          ) ? penalty * BigNumber.parse('0.50') : BigNumber.fromInt(0);
          final extraPenalty = penalty * BigNumber.parse(
            traitEffects.riskMissPenaltyRate.toStringAsFixed(2),
          );
          final remainingMoney = beforeGuess.money - penalty + refund + adaptiveRefund - extraPenalty;
          afterReward = afterReward.copyWith(
            money: remainingMoney.compareTo(BigNumber.fromInt(0)) < 0
                ? BigNumber.fromInt(0)
                : remainingMoney,
            currentStreak: traitEffects.streakProtection ||
                    adaptiveDecision.helperIds.contains(InvisibleTraitEngine.helperStreakGuard)
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
        var systemsAfter = _legacySystemsEngine.recordGuessProgress(
          legacySystems,
          correct: correct,
          currentStreak: afterReward.currentStreak,
          today: DateTime.now().toIso8601String().substring(0, 10),
          lootRoll: correct ? Random.secure().nextInt(1000) : null,
        ).copyWith(adaptiveTraitProfile: adaptiveProfileAfter);
        systemsAfter = _legacySystemsEngine.discoverEligibleTraits(
          progression: afterReward,
          systems: systemsAfter,
          playerLevel: 1,
          activeSeasonId: _currentSeasonId(),
        );
        var nextProgression = afterReward.copyWith(legacySystems: systemsAfter);
        if (systemsAfter.endlessRiftActive) {
          final riftResult = correct
              ? _legacySystemsEngine.attackEndlessRiftBoss(nextProgression, systemsAfter)
              : _legacySystemsEngine.recordEndlessRiftMiss(nextProgression, systemsAfter);
          if (riftResult.accepted) {
            nextProgression = riftResult.progression.copyWith(
              legacySystems: riftResult.systems,
            );
          }
        }
        _progression = nextProgression;
      }
      switch (_game.lastResult) {
        case GuessResult.tooLow:
          _message = rangeScoutActive
              ? 'Range Scout narrowed the search to ${_game.minimum}–${_game.maximum}.'
              : _progression.legacySystems.activeMutators.contains('mut_blind')
                  ? 'Guess recorded. Try again.'
                  : 'Too low. Try a higher number!';
        case GuessResult.tooHigh:
          _message = rangeScoutActive
              ? 'Range Scout narrowed the search to ${_game.minimum}–${_game.maximum}.'
              : _progression.legacySystems.activeMutators.contains('mut_blind')
                  ? 'Guess recorded. Try again.'
                  : 'Too high. Try a lower number!';
        case GuessResult.correct:
          _gamesWon++;
          _message =
              'Correct! You got it in ${_game.attempts} ${_game.attempts == 1 ? 'try' : 'tries'}.';
        case GuessResult.outOfRange:
          _message = 'Choose a number between ${_game.minimum} and ${_game.maximum}.';
        case null:
          break;
      }
    });
    _controller.clear();
    await _persist();
  }

  Future<void> _newGame() async {
    setState(() {
      _game = _newGameWithAdaptiveTarget(_engine.newGame());
      _message = 'New round! Guess a number between ${_game.minimum} and ${_game.maximum}.';
      _controller.clear();
    });
    await _persist();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameDashboardPage(
      game: _game,
      progression: _progression,
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
      showDeveloperSettings: kDebugMode,
    );
  }
}
