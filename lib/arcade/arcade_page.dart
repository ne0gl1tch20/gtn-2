import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/numbers/big_number.dart';

typedef ArcadeRewardCallback = Future<void> Function(
  BigNumber nebula,
  BigNumber money,
);

class ArcadePage extends StatelessWidget {
  const ArcadePage({super.key, required this.onReward});

  final ArcadeRewardCallback onReward;

  static const _games = [
    ('quick_guess', 'Quick Guess', 'Solve as many 1–9 guesses as you can in 10 seconds.', Icons.timer_rounded),
    ('reaction_test', 'Reaction Test', 'Tap as soon as the signal turns green.', Icons.flash_on_rounded),
    ('lucky_number', 'Lucky Number Box', 'Choose one of three mystery boxes.', Icons.card_giftcard_rounded),
    ('memory_match', 'Memory Digit Sequence', 'Memorize and repeat a short digit sequence.', Icons.memory_rounded),
    ('number_rush', 'Number Rush', 'Tap numbers in ascending order from 1 to 5.', Icons.numbers_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arcade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Play quick minigames to earn Nebula and bonus Money. Each completed run can only pay once.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final game in _games)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(game.$4, size: 32),
                title: Text(game.$2),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(game.$3),
                ),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => _ArcadeDialog(
                    gameId: game.$1,
                    title: game.$2,
                    onReward: onReward,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArcadeDialog extends StatefulWidget {
  const _ArcadeDialog({
    required this.gameId,
    required this.title,
    required this.onReward,
  });

  final String gameId;
  final String title;
  final ArcadeRewardCallback onReward;

  @override
  State<_ArcadeDialog> createState() => _ArcadeDialogState();
}

class _ArcadeDialogState extends State<_ArcadeDialog> {
  final _random = Random();
  final _input = TextEditingController();
  Timer? _timer;
  int _timeLeft = 10;
  int _score = 0;
  int _target = 1;
  int? _chosenBox;
  late final int _winningBox = _random.nextInt(3) + 1;
  late final List<int> _sequence = List.generate(3, (_) => _random.nextInt(9) + 1);
  late final List<int> _numbers = (List<int>.generate(5, (i) => i + 1)..shuffle(_random));
  int _nextNumber = 1;
  bool _finished = false;
  bool _sequenceVisible = true;
  bool _reactionReady = false;
  bool _reactionFinished = false;
  int? _reactionTime;
  late final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    switch (widget.gameId) {
      case 'quick_guess':
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_timeLeft <= 1) {
            timer.cancel();
            if (mounted) setState(() { _timeLeft = 0; _finished = true; });
          } else if (mounted) {
            setState(() => _timeLeft--);
          }
        });
      case 'reaction_test':
        Future<void>.delayed(Duration(milliseconds: 1000 + _random.nextInt(2000)), () {
          if (mounted && !_reactionFinished) {
            setState(() {
              _reactionReady = true;
              _stopwatch.start();
            });
          }
        });
      case 'memory_match':
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _sequenceVisible = false);
        });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    if (_finished && widget.gameId == 'quick_guess') {
      await widget.onReward(
        BigNumber.fromInt(1),
        BigNumber.fromInt(_score * 500),
      );
    } else if (widget.gameId == 'reaction_test' &&
        _reactionFinished &&
        _reactionTime != null &&
        _reactionTime != 9999) {
      await widget.onReward(BigNumber.fromInt(1), BigNumber.fromInt(2000));
    } else if (widget.gameId == 'lucky_number' &&
        _chosenBox == _winningBox) {
      await widget.onReward(BigNumber.fromInt(1), BigNumber.fromInt(5000));
    } else if (widget.gameId == 'memory_match' && _finished) {
      await widget.onReward(BigNumber.fromInt(1), BigNumber.fromInt(10000));
    } else if (widget.gameId == 'number_rush' && _finished) {
      await widget.onReward(BigNumber.fromInt(1), BigNumber.fromInt(7500));
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _guess() {
    final value = int.tryParse(_input.text.trim());
    if (value == _target) {
      setState(() {
        _score++;
        _target = _random.nextInt(9) + 1;
      });
    }
    _input.clear();
  }

  void _tapReaction() {
    if (_reactionFinished) return;
    if (!_reactionReady) {
      setState(() {
        _reactionFinished = true;
        _reactionTime = 9999;
      });
      return;
    }
    _stopwatch.stop();
    setState(() {
      _reactionFinished = true;
      _reactionTime = _stopwatch.elapsedMilliseconds;
    });
  }

  Widget _gameContent() {
    switch (widget.gameId) {
      case 'quick_guess':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Time left: $_timeLeft seconds'),
            Text('Score: $_score', style: Theme.of(context).textTheme.headlineSmall),
            if (!_finished) ...[
              Text('Guess the target: $_target'),
              TextField(
                controller: _input,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Your guess (1–9)'),
                onSubmitted: (_) => _guess(),
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _guess, child: const Text('Guess')),
            ] else
              const Text('Time is up!'),
          ],
        );
      case 'reaction_test':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _reactionFinished
                  ? (_reactionTime == 9999 ? 'Too early!' : 'Reaction: ${_reactionTime}ms')
                  : (_reactionReady ? 'TAP NOW!' : 'Wait for green…'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _reactionFinished ? null : _tapReaction,
              child: const Text('TAP'),
            ),
          ],
        );
      case 'lucky_number':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose one of the three mystery boxes.'),
            const SizedBox(height: 12),
            if (_chosenBox == null)
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 1; i <= 3; i++)
                    FilledButton(
                      onPressed: () => setState(() => _chosenBox = i),
                      child: Text('Box $i'),
                    ),
                ],
              )
            else
              Text(
                _chosenBox == _winningBox
                    ? '🎉 Jackpot! You found the lucky box!'
                    : 'Empty box! The winning box was $_winningBox.',
              ),
          ],
        );
      case 'memory_match':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_sequenceVisible)
              Text(
                _sequence.join('  '),
                style: Theme.of(context).textTheme.headlineMedium,
              )
            else if (!_finished) ...[
              const Text('Enter the three digits in the same order.'),
              TextField(
                controller: _input,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sequence'),
              ),
              FilledButton(
                onPressed: () => setState(() {
                  _finished = _input.text.trim() == _sequence.join();
                }),
                child: const Text('Submit'),
              ),
              if (_input.text.isNotEmpty && _input.text.trim() != _sequence.join())
                const Text('Not quite. Try again.'),
            ] else
              const Text('Correct! You remembered the sequence.'),
          ],
        );
      case 'number_rush':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tap in order: $_nextNumber of 5'),
            Wrap(
              spacing: 8,
              children: [
                for (final number in _numbers)
                  FilledButton(
                    onPressed: _finished
                        ? null
                        : () => setState(() {
                              if (number == _nextNumber) {
                                if (_nextNumber == 5) {
                                  _finished = true;
                                } else {
                                  _nextNumber++;
                                }
                              } else {
                                _nextNumber = 1;
                              }
                            }),
                    child: Text('$number'),
                  ),
              ],
            ),
            if (_finished) const Text('Rush completed!'),
          ],
        );
      default:
        return const Text('Unknown minigame.');
    }
  }

  bool get _canClaim {
    switch (widget.gameId) {
      case 'quick_guess':
        return _finished;
      case 'reaction_test':
        return _reactionFinished;
      case 'lucky_number':
        return _chosenBox != null;
      case 'memory_match':
        return _finished;
      case 'number_rush':
        return _finished;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: _gameContent(),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (_canClaim)
          FilledButton(
            onPressed: _claim,
            child: const Text('Claim reward'),
          ),
      ],
    );
  }
}
