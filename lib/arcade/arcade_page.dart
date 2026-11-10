import 'dart:async';
import 'dart:math';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/numbers/big_number.dart';
import '../design/expressive_widgets.dart';
import 'arcade_catalog.dart';
import 'arcade_reward_rules.dart';

typedef ArcadeRewardCallback = Future<void> Function(
  BigNumber nebula,
  BigNumber money,
);

class ArcadePage extends StatefulWidget {
  const ArcadePage({super.key, required this.onReward});

  final ArcadeRewardCallback onReward;

  @override
  State<ArcadePage> createState() => _ArcadePageState();
}

class _ArcadePageState extends State<ArcadePage> {
  late Future<List<ArcadeGameDefinition>> _catalog = ArcadeCatalog.load();

  IconData _iconFor(String id) => switch (id) {
        'quick_guess' => Icons.timer_rounded,
        'reaction_test' => Icons.flash_on_rounded,
        'lucky_number' => Icons.card_giftcard_rounded,
        'memory_match' => Icons.memory_rounded,
        'number_rush' => Icons.numbers_rounded,
        'math_blitz' => Icons.calculate_rounded,
        'memory_grid' => Icons.grid_on_rounded,
        _ => Icons.sports_esports_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: const Text('Arcade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Play the original seven GTN1 minigames to earn Nebula and Money.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<ArcadeGameDefinition>>(
            future: _catalog,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: M3EProgressIndicator.circular()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return GtnExpressiveCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 32),
                        const SizedBox(height: 8),
                        const Text('The original Arcade catalog could not be loaded.'),
                        const SizedBox(height: 8),
                        M3EButton.filled(
                          onPressed: () => setState(() {
                            _catalog = ArcadeCatalog.load();
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (final game in snapshot.data!)
                    GtnExpressiveCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(_iconFor(game.id), size: 32),
                        title: Text(game.name),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(game.description),
                        ),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () => GtnExpressiveDialog.show<void>(
                          context: context,
                          builder: (_) => _ArcadeDialog(
                            gameId: game.id,
                            title: game.name,
                            onReward: widget.onReward,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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
  late final List<int> _sequence =
      List.generate(3, (_) => _random.nextInt(9) + 1);
  late final List<int> _numbers =
      (List<int>.generate(5, (i) => i + 1)..shuffle(_random));
  int _nextNumber = 1;
  bool _finished = false;
  bool _sequenceVisible = true;
  bool _memorySubmitted = false;
  bool _memoryCorrect = false;
  bool _reactionReady = false;
  bool _reactionFinished = false;
  int? _reactionTime;
  late final Stopwatch _reactionStopwatch = Stopwatch();
  final Stopwatch _roundStopwatch = Stopwatch();

  late int _mathFirst = _random.nextInt(11) + 2;
  late int _mathSecond = _random.nextInt(11) + 2;
  late int _mathOperation = _random.nextInt(3);
  int get _mathAnswer => switch (_mathOperation) {
        0 => _mathFirst + _mathSecond,
        1 => _mathFirst * _mathSecond,
        _ => _mathFirst - _mathSecond,
      };
  late List<int> _mathChoices = _choicesFor(_mathAnswer);

  late final List<int> _gridCards =
      (List<int>.generate(16, (index) => index ~/ 2 + 1)..shuffle(_random));
  final List<int> _gridSelected = [];
  final Set<int> _gridMatched = {};
  int _gridMoves = 0;

  @override
  void initState() {
    super.initState();
    _roundStopwatch.start();
    switch (widget.gameId) {
      case 'quick_guess':
        _startCountdown(10);
      case 'math_blitz':
      case 'memory_grid':
        _timeLeft = 60;
        _startCountdown(60);
      case 'reaction_test':
        Future<void>.delayed(
          Duration(milliseconds: 1000 + _random.nextInt(2000)),
          () {
            if (mounted && !_reactionFinished) {
              setState(() {
                _reactionReady = true;
                _reactionStopwatch.start();
              });
            }
          },
        );
      case 'memory_match':
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _sequenceVisible = false);
        });
    }
  }

  void _startCountdown(int seconds) {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
      } else if (_finished || _timeLeft <= 1) {
        timer.cancel();
        setState(() {
          _timeLeft = 0;
          _finished = true;
        });
      } else {
        setState(() => _timeLeft--);
      }
    });
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
        ArcadeRewardRules.isReactionTestRewardEligible(_reactionTime!)) {
      await widget.onReward(BigNumber.fromInt(1), BigNumber.fromInt(2000));
    } else if (widget.gameId == 'lucky_number' &&
        _chosenBox == _winningBox) {
      await widget.onReward(BigNumber.fromInt(1), BigNumber.fromInt(5000));
    } else if (widget.gameId == 'memory_match' &&
        ArcadeRewardRules.isMemoryMatchRewardEligible(
          submitted: _memorySubmitted,
          correct: _memoryCorrect,
        )) {
      await widget.onReward(BigNumber.fromInt(1), BigNumber.fromInt(10000));
    } else if (widget.gameId == 'number_rush' && _finished) {
      await widget.onReward(BigNumber.fromInt(1), BigNumber.fromInt(7500));
    } else if ((widget.gameId == 'math_blitz' ||
            widget.gameId == 'memory_grid') &&
        _finished) {
      final elapsed = _roundStopwatch.elapsed.inSeconds.clamp(1, 600).toInt();
      final nebula = ArcadeRewardRules.calculateNebulaReward(elapsed, _score);
      final money = ArcadeRewardRules.calculateMoneyReward(elapsed, _score);
      await widget.onReward(
        BigNumber.fromInt(nebula),
        BigNumber.fromInt(money),
      );
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
        _reactionTime = ArcadeRewardRules.tooEarlyReactionSentinel;
      });
      return;
    }
    _reactionStopwatch.stop();
    setState(() {
      _reactionFinished = true;
      _reactionTime = _reactionStopwatch.elapsedMilliseconds;
    });
  }

  List<int> _choicesFor(int answer) {
    final choices = <int>{answer};
    while (choices.length < 4) {
      choices.add(answer + _random.nextInt(25) - 12);
    }
    final result = choices.toList()..shuffle(_random);
    return result;
  }

  void _answerMath(int choice) {
    if (_finished) return;
    setState(() {
      if (choice == _mathAnswer) _score++;
      _mathFirst = _random.nextInt(11) + 2;
      _mathSecond = _random.nextInt(11) + 2;
      _mathOperation = _random.nextInt(3);
      _mathChoices = _choicesFor(_mathAnswer);
    });
  }

  void _flipGridCard(int index) {
    if (_finished ||
        _gridSelected.length >= 2 ||
        _gridSelected.contains(index) ||
        _gridMatched.contains(index)) {
      return;
    }
    setState(() {
      _gridSelected.add(index);
      if (_gridSelected.length == 2) _gridMoves++;
    });
    if (_gridSelected.length != 2) return;

    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _gridSelected.length != 2) return;
      final first = _gridSelected[0];
      final second = _gridSelected[1];
      setState(() {
        if (_gridCards[first] == _gridCards[second]) {
          _gridMatched.add(first);
          _gridMatched.add(second);
          _score += 2;
          if (_gridMatched.length == _gridCards.length) {
            _finished = true;
            _timer?.cancel();
          }
        } else {
          _score = (_score - 1).clamp(0, 1 << 30).toInt();
        }
        _gridSelected.clear();
      });
    });
  }

  Widget _gameContent() {
    switch (widget.gameId) {
      case 'quick_guess':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Time left: $_timeLeft seconds'),
            Text(
              'Score: $_score',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (!_finished) ...[
              Text('Guess the target: $_target'),
              GtnExpressiveTextField(
                controller: _input,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Your guess (1–9)'),
                onSubmitted: (_) => _guess(),
              ),
              const SizedBox(height: 8),
              M3EButton.filled(onPressed: _guess, child: const Text('Guess')),
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
                  ? (_reactionTime == ArcadeRewardRules.tooEarlyReactionSentinel
                      ? 'Too early!'
                      : 'Reaction: ${_reactionTime}ms')
                  : (_reactionReady ? 'TAP NOW!' : 'Wait for green…'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            M3EButton.filled(
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
                    M3EButton.filled(
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
            else if (!_memorySubmitted) ...[
              const Text('Enter the three digits in the same order.'),
              GtnExpressiveTextField(
                controller: _input,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sequence'),
              ),
              M3EButton.filled(
                onPressed: () => setState(() {
                  _memoryCorrect = _input.text.trim() == _sequence.join();
                  _memorySubmitted = true;
                  _finished = true;
                }),
                child: const Text('Submit'),
              ),
            ] else
              Text(
                _memoryCorrect
                    ? 'Correct! You remembered the sequence.'
                    : 'Incorrect! Expected ${_sequence.join()}',
              ),
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
                  M3EButton.filled(
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
      case 'math_blitz':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: $_score'),
                Text('Time: ${_timeLeft}s'),
              ],
            ),
            M3EProgressIndicator.linearWavy(value: _timeLeft / 60),
            const SizedBox(height: 12),
            if (!_finished) ...[
              Text(
                '$_mathFirst ${['+', '×', '−'][_mathOperation]} $_mathSecond = ?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _mathChoices)
                    M3EButton.filled(
                      onPressed: () => _answerMath(option),
                      child: Text('$option'),
                    ),
                ],
              ),
            ] else ...[
              const Text('Time is up!'),
              Text('Final score: $_score'),
            ],
          ],
        );
      case 'memory_grid':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: $_score'),
                Text('Time: ${_timeLeft}s'),
              ],
            ),
            M3EProgressIndicator.linearWavy(value: _timeLeft / 60),
            const SizedBox(height: 8),
            Text('Find all 8 matching pairs. Moves: $_gridMoves'),
            const SizedBox(height: 8),
            if (!_finished)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gridCards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final revealed = _gridSelected.contains(index) ||
                      _gridMatched.contains(index);
                  return M3EButton.filled(
                    onPressed: revealed || _gridSelected.length >= 2
                        ? null
                        : () => _flipGridCard(index),
                    
                    child: Text(
                      revealed ? '${_gridCards[index]}' : '?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  );
                },
              )
            else
              Text(
                _gridMatched.length == _gridCards.length
                    ? 'Grid cleared!'
                    : 'Time is up!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            if (_finished) Text('Final score: $_score'),
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
        return _memorySubmitted;
      case 'number_rush':
      case 'math_blitz':
      case 'memory_grid':
        return _finished;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GtnExpressiveDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(child: _gameContent()),
      actions: [
        M3EButton.text(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (_canClaim)
          M3EButton.filled(
            onPressed: _claim,
            child: Text(
              widget.gameId == 'memory_match' && !_memoryCorrect
                  ? 'Done'
                  : 'Claim reward',
            ),
          ),
      ],
    );
  }
}
