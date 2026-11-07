import 'package:flutter/material.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C5CFC), brightness: Brightness.dark),
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
  static const int _minimum = 1;
  static const int _maximum = 100;
  int _secret = 42;
  int _attempts = 0;
  String _message = 'Guess a number between $_minimum and $_maximum.';
  final TextEditingController _controller = TextEditingController();

  void _submitGuess() {
    final int? guess = int.tryParse(_controller.text.trim());
    if (guess == null || guess < _minimum || guess > _maximum) {
      setState(() => _message = 'Enter a whole number from $_minimum to $_maximum.');
      return;
    }
    setState(() {
      _attempts++;
      if (guess == _secret) {
        _message = 'Correct! You got it in $_attempts ${_attempts == 1 ? 'try' : 'tries'}.';
      } else if (guess < _secret) {
        _message = 'Too low. Try a higher number!';
      } else {
        _message = 'Too high. Try a lower number!';
      }
    });
    _controller.clear();
  }

  void _newGame() {
    setState(() {
      _secret = DateTime.now().microsecondsSinceEpoch % _maximum + _minimum;
      _attempts = 0;
      _message = 'New round! Guess a number between $_minimum and $_maximum.';
      _controller.clear();
    });
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
                Text(_message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('Attempts: $_attempts', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitGuess(),
                  decoration: const InputDecoration(labelText: 'Your guess', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _submitGuess, child: const Text('Guess')),
                TextButton(onPressed: _newGame, child: const Text('New game')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
