import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/creative/creative_mode.dart';

void main() {
  CreativeModeSave config({
    List<CreativeModeEffect> effects = const [],
    bool enabled = true,
  }) =>
      CreativeModeSave(
        enabled: enabled,
        rangeMin: 10,
        rangeMax: 20,
        effects: effects,
      );

  test('starts a run inside the validated configured range', () {
    final save = config(
      effects: const [
        CreativeModeEffect(
          id: 'extra-hints',
          type: CreativeEffectType.extraHints,
          value: 2,
        ),
      ],
    );
    final run = CreativeModeRuntime.start(save, 15);
    expect(run, isNotNull);
    expect(run!.rangeMin, 10);
    expect(run.rangeMax, 20);
    expect(run.attemptsUsed, 0);
    expect(run.correctGuesses, 0);
    expect(run.runId, matches(RegExp(r'^[a-f0-9]{32}$')));
  });

  test('wrong guesses consume one attempt and a correct guess completes', () {
    final save = config(
      effects: const [
        CreativeModeEffect(
          id: 'limit',
          type: CreativeEffectType.attemptLimit,
          value: 3,
        ),
      ],
    );
    final run = CreativeModeRuntime.start(save, 15)!;
    final low = CreativeModeRuntime.submitGuess(save, run, 12);
    expect(low.outcome, CreativeGuessOutcome.tooLow);
    expect(low.run.attemptsUsed, 1);
    final correct = CreativeModeRuntime.submitGuess(save, low.run, 15);
    expect(correct.outcome, CreativeGuessOutcome.correct);
    expect(correct.run.completed, isTrue);
    expect(correct.run.correctGuesses, 1);
    final after = CreativeModeRuntime.submitGuess(save, correct.run, 15);
    expect(after.accepted, isFalse);
    expect(after.outcome, CreativeGuessOutcome.completed);
  });

  test('out-of-range guesses and exhausted attempt limits do not consume attempts', () {
    final save = config(
      effects: const [
        CreativeModeEffect(
          id: 'limit',
          type: CreativeEffectType.attemptLimit,
          value: 1,
        ),
      ],
    );
    final run = CreativeModeRuntime.start(save, 15)!;
    final outside = CreativeModeRuntime.submitGuess(save, run, 9);
    expect(outside.outcome, CreativeGuessOutcome.outOfRange);
    expect(outside.run.attemptsUsed, 0);
    final first = CreativeModeRuntime.submitGuess(save, run, 12);
    expect(first.run.attemptsUsed, 1);
    final blocked = CreativeModeRuntime.submitGuess(save, first.run, 15);
    expect(blocked.outcome, CreativeGuessOutcome.attemptLimit);
    expect(blocked.accepted, isFalse);
    expect(blocked.run.attemptsUsed, 1);
  });

  test('hints are bounded and unavailable after completion', () {
    final save = config(
      effects: const [
        CreativeModeEffect(
          id: 'hints',
          type: CreativeEffectType.extraHints,
          value: 1,
        ),
      ],
    );
    final run = CreativeModeRuntime.start(save, 15)!;
    final used = CreativeModeRuntime.useHint(save, run)!;
    expect(used.hintsUsed, 1);
    expect(CreativeModeRuntime.useHint(save, used), isNull);
    final completed = CreativeModeRuntime.submitGuess(save, used, 15).run;
    expect(CreativeModeRuntime.useHint(save, completed), isNull);
  });

  test('disabled configuration and targets outside range cannot start', () {
    expect(
      CreativeModeRuntime.start(config(enabled: false), 15),
      isNull,
    );
    expect(CreativeModeRuntime.start(config(), 21), isNull);
  });

  test('active run survives codec round trip and resumes exactly', () {
    final save = config(
      effects: const [
        CreativeModeEffect(
          id: 'hints',
          type: CreativeEffectType.extraHints,
          value: 2,
        ),
      ],
    );
    final run = CreativeModeRuntime.start(save, 15)!;
    final firstGuess = CreativeModeRuntime.submitGuess(save, run, 12).run;
    final usedHint = CreativeModeRuntime.useHint(save, firstGuess)!;
    final persisted = CreativeModeRuntime.persist(save, usedHint)!;
    final encoded = CreativeModeSave.encode(persisted);
    final decoded = CreativeModeSave.decodeAndMigrate(encoded)!;
    final resumed = CreativeModeRuntime.resume(decoded)!;
    expect(resumed.runId, usedHint.runId);
    expect(resumed.attemptsUsed, usedHint.attemptsUsed);
    expect(resumed.hintsUsed, usedHint.hintsUsed);
    expect(resumed.target, usedHint.target);
  });

  test('version two Creative Mode saves migrate without inventing a run', () {
    const old =
        '{"schemaVersion":2,"name":"Old v2","enabled":true,"rangeMin":1,"rangeMax":40,"effects":[]}';
    final migrated = CreativeModeSave.decodeAndMigrate(old);
    expect(migrated, isNotNull);
    expect(migrated!.schemaVersion, CreativeModeSave.currentSchemaVersion);
    expect(migrated.activeRun, isNull);
  });

  test('rejects invalid and forged run snapshots', () {
    const invalid = CreativeModeRunSnapshot(
      runId: 'short',
      rangeMin: 1,
      rangeMax: 10,
      target: 11,
      attemptsUsed: -1,
    );
    expect(CreativeModeSave.validateRunSnapshot(invalid), isFalse);
    final save = config(
      effects: const [
        CreativeModeEffect(
          id: 'hints',
          type: CreativeEffectType.extraHints,
          value: 1,
        ),
      ],
    );
    final valid = CreativeModeRuntime.start(save, 15)!;
    final forged = CreativeModeRun(
      runId: valid.runId,
      rangeMin: valid.rangeMin,
      rangeMax: 100,
      target: valid.target,
    );
    expect(
      CreativeModeRuntime.submitGuess(save, forged, 15).outcome,
      CreativeGuessOutcome.invalidConfiguration,
    );
    expect(CreativeModeRuntime.persist(save, forged), isNull);
  });

  test('all creative effects compose into bounded rules', () {
    final save = CreativeModeSave(
      enabled: true,
      rangeMin: 10,
      rangeMax: 20,
      effects: const [
        CreativeModeEffect(
          id: 'scale-range',
          type: CreativeEffectType.rangeScale,
          value: 2,
        ),
        CreativeModeEffect(
          id: 'extra-hints',
          type: CreativeEffectType.extraHints,
          value: 3,
        ),
        CreativeModeEffect(
          id: 'limit-attempts',
          type: CreativeEffectType.attemptLimit,
          value: 4,
        ),
        CreativeModeEffect(
          id: 'more-hints',
          type: CreativeEffectType.extraHints,
          value: 4,
        ),
        CreativeModeEffect(
          id: 'stricter-limit',
          type: CreativeEffectType.attemptLimit,
          value: 2,
        ),
      ],
    );
    final rules = CreativeModeEffectPolicy.resolve(save)!;
    expect(rules.rangeMin, 10);
    expect(rules.rangeMax, 31);
    expect(rules.extraHints, 7);
    expect(rules.attemptLimit, 2);
    final run = CreativeModeRuntime.start(save, 30)!;
    expect(
      CreativeModeRuntime.submitGuess(save, run, 31).outcome,
      CreativeGuessOutcome.tooHigh,
    );
  });

  test('completed snapshots must represent a correct guess', () {
    const invalid = CreativeModeRunSnapshot(
      runId: 'creative-run-123',
      rangeMin: 1,
      rangeMax: 10,
      target: 5,
      completed: true,
    );
    expect(CreativeModeSave.validateRunSnapshot(invalid), isFalse);
    const raw =
        '{"schemaVersion":3,"name":"Creative","enabled":true,"rangeMin":1,"rangeMax":100,"effects":[],"activeRun":{"runId":"creative-run-123","rangeMin":1,"rangeMax":10,"target":5,"attemptsUsed":0,"correctGuesses":0,"hintsUsed":0,"completed":true}}';
    expect(CreativeModeSave.decodeAndMigrate(raw), isNull);
  });
}
