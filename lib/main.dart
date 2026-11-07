import 'dart:async';

import 'package:flutter/material.dart';

import 'core/game/game_engine.dart';
import 'data/saves/save_data.dart';
import 'data/saves/save_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GtnApp());
}

class GtnApp extends StatelessWidget {
  const GtnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuessTheNumber 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFC),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameHomePage(),
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
  final TextEditingController _controller = TextEditingController();
  late GameState _game = _engine.newGame();
  late final Future<SaveStorage> _storage =
      SaveStorage.inApplicationDocuments();
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
            isComplete: false,
          );
          _gamesWon = save.gamesWon;
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
        ),
      );
    } on Exception {
      if (mounted) {
        setState(() => _message = 'Game is still playable, but saving failed.');
      }
    }
  }

  Future<void> _submitGuess() async {
    final guess = int.tryParse(_controller.text.trim());
    if (guess == null) {
      setState(() => _message = 'Enter a whole number from 1 to 100.');
      return;
    }

    setState(() {
      _game = _engine.guess(_game, guess);
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
    return Scaffold(
      appBar: AppBar(title: const Text('GuessTheNumber 2')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.casino_rounded, size: 64),
                const SizedBox(height: 24),
                Text(
                  _isLoading ? 'Loading saved game…' : _message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Attempts: ${_game.attempts}  •  Games won: $_gamesWon',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  enabled: !_isLoading && !_game.isComplete,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitGuess(),
                  decoration: const InputDecoration(
                    labelText: 'Your guess',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isLoading || _game.isComplete
                      ? null
                      : _submitGuess,
                  child: const Text('Guess'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _newGame,
                  child: const Text('New game'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
