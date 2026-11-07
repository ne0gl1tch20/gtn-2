import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'home/game_dashboard_page.dart';

import 'arcade/arcade_page.dart';
import 'core/game/game_engine.dart';
import 'core/numbers/big_number.dart';
import 'core/progression/progression_calculator.dart';
import 'core/progression/progression_engine.dart';
import 'core/progression/progression_state.dart';
import 'data/saves/save_data.dart';
import 'data/saves/save_storage.dart';
import 'dev/developer_settings_page.dart';
import 'progression/progression_hub_page.dart';
import 'saves/save_slots_page.dart';
import 'settings/game_settings.dart';
import 'settings/settings_page.dart';
import 'shop/nebula_shop_page.dart';
import 'shop/upgrade_catalog.dart';
import 'shop/upgrade_shop_page.dart';
import 'worlds/world_boss_catalog.dart';
import 'worlds/world_map_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GtnApp());
}

class GtnApp extends StatelessWidget {
  const GtnApp({super.key});

  static final ValueNotifier<GameSettings> settingsNotifier =
      ValueNotifier<GameSettings>(GameSettings.initial);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameSettings>(
      valueListenable: settingsNotifier,
      builder: (context, settings, _) {
        ThemeData makeTheme(Brightness brightness) => ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF7C5CFC),
                brightness: brightness,
              ),
              useMaterial3: true,
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
    );
  }
}

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});

  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage> {
  final GameEngine _engine = GameEngine();
  final ProgressionEngine _progressionEngine = const ProgressionEngine();
  ProgressionState _progression = ProgressionState.initial;
  GameSettings _settings = GameSettings.initial;
  final TextEditingController _controller = TextEditingController();
  late GameState _game = _engine.newGame();
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
        setState(() {
          _game = _engine.restore(
            secret: save.secret,
            attempts: save.attempts,
            isComplete: save.isComplete,
          );
          _gamesWon = save.gamesWon;
          _progression = save.progression;
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
      setState(() => _progression = updated);
      await _persist();
    }
    return _progression;
  }


  Future<void> _prestige() async {
    final updated = _progressionEngine.prestige(
      _progression,
      ProgressionCalculator.prestigeRules(_progression),
    );
    if (updated != _progression) {
      setState(() {
        _progression = updated;
        _game = _engine.newGame();
        _message = 'Prestige complete! Build your progress again.';
      });
      await _persist();
    }
  }

  Future<void> _ultra() async {
    if (_progression.prestige.compareTo(BigNumber.fromInt(1000)) < 0) return;
    final updated = _progressionEngine.ultra(
      _progression,
      ProgressionCalculator.ultraRules(_progression),
    );
    if (updated != _progression) {
      setState(() {
        _progression = updated;
        _game = _engine.newGame();
        _message = 'Ultra reset complete! A new run begins.';
      });
      await _persist();
    }
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
      setState(() {
        _storage = Future.value(storage);
        _activeSlot = slot;
        _game = save == null
            ? _engine.newGame()
            : _engine.restore(
                secret: save.secret,
                attempts: save.attempts,
                isComplete: save.isComplete,
              );
        _gamesWon = save?.gamesWon ?? 0;
        _progression = save?.progression ?? ProgressionState.initial;
        _settings = save?.settings ?? GameSettings.initial;
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
    setState(() => _settings = settings);
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
        progression: _progression,
        settings: _settings,
      );

  Future<void> _applyDeveloperSave(SaveData save) async {
    setState(() {
      _game = _engine.restore(
        secret: save.secret,
        attempts: save.attempts,
        isComplete: save.isComplete,
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
        _game = _engine.newGame();
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

  Future<void> _submitGuess() async {
    final guess = int.tryParse(_controller.text.trim());
    if (guess == null) {
      setState(() => _message = 'Enter a whole number from 1 to 100.');
      return;
    }

    setState(() {
      final previousAttempts = _game.attempts;
      _game = _engine.guess(_game, guess);
      if (_game.attempts > previousAttempts) {
        final correct = _game.lastResult == GuessResult.correct;
        final effects = UpgradeCatalog.effectsFor(
          _progression,
          isFirstGuess: _game.attempts == 1,
        );
        _progression = _progressionEngine.recordGuess(
          _progression,
          correct: correct,
          baseReward: correct ? BigNumber.fromInt(1) : null,
          flatBonusReward: correct ? effects.flatBonus : null,
          modifiers: GuessRewardModifiers(
            streakMultiplier: effects.streakMultiplier,
            criticalMultiplier: effects.firstGuessMultiplier *
                ((_progression.nebulaItems['golden_guess'] ?? 0) > 0 &&
                        (_progression.totalGuesses + 1) % 10 == 0
                    ? 2
                    : 1),
          ),
        );
      }
      switch (_game.lastResult) {
        case GuessResult.tooLow:
          _message = 'Too low. Try a higher number!';
        case GuessResult.tooHigh:
          _message = 'Too high. Try a lower number!';
        case GuessResult.correct:
          _gamesWon++;
          _message =
              'Correct! You got it in ${_game.attempts} ${_game.attempts == 1 ? 'try' : 'tries'}.';
        case GuessResult.outOfRange:
          _message = 'Choose a number between 1 and 100.';
        case null:
          break;
      }
    });
    _controller.clear();
    await _persist();
  }

  Future<void> _newGame() async {
    setState(() {
      _game = _engine.newGame();
      _message = 'New round! Guess a number between 1 and 100.';
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
      gamesWon: _gamesWon,
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
      showDeveloperSettings: kDebugMode,
    );
  }
}
