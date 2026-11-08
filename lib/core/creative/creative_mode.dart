import 'dart:convert';
import 'dart:math';

enum CreativeEffectType { rangeScale, extraHints, attemptLimit }

enum CreativeGuessOutcome {
  tooLow,
  tooHigh,
  correct,
  outOfRange,
  attemptLimit,
  completed,
  invalidConfiguration,
}

class CreativeModeEffect {
  const CreativeModeEffect({
    required this.id,
    required this.type,
    required this.value,
  });

  final String id;
  final CreativeEffectType type;
  final int value;

  Map<String, Object> toJson() => {
        'id': id,
        'type': switch (type) {
          CreativeEffectType.rangeScale => 'RANGE_SCALE',
          CreativeEffectType.extraHints => 'EXTRA_HINTS',
          CreativeEffectType.attemptLimit => 'ATTEMPT_LIMIT',
        },
        'value': value,
      };

  factory CreativeModeEffect.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final rawType = json['type'];
    final value = json['value'];
    if (id is! String || rawType is! String || value is! int) {
      throw const FormatException('Invalid creative-mode effect.');
    }
    final type = switch (rawType) {
      'RANGE_SCALE' => CreativeEffectType.rangeScale,
      'EXTRA_HINTS' => CreativeEffectType.extraHints,
      'ATTEMPT_LIMIT' => CreativeEffectType.attemptLimit,
      _ => throw const FormatException('Unknown creative-mode effect type.'),
    };
    return CreativeModeEffect(id: id, type: type, value: value);
  }
}

class CreativeModeRunSnapshot {
  const CreativeModeRunSnapshot({
    required this.runId,
    required this.rangeMin,
    required this.rangeMax,
    required this.target,
    this.attemptsUsed = 0,
    this.correctGuesses = 0,
    this.hintsUsed = 0,
    this.completed = false,
  });

  final String runId;
  final int rangeMin;
  final int rangeMax;
  final int target;
  final int attemptsUsed;
  final int correctGuesses;
  final int hintsUsed;
  final bool completed;

  Map<String, Object> toJson() => {
        'runId': runId,
        'rangeMin': rangeMin,
        'rangeMax': rangeMax,
        'target': target,
        'attemptsUsed': attemptsUsed,
        'correctGuesses': correctGuesses,
        'hintsUsed': hintsUsed,
        'completed': completed,
      };

  factory CreativeModeRunSnapshot.fromJson(Map<String, dynamic> json) {
    final runId = json['runId'];
    final rangeMin = json['rangeMin'];
    final rangeMax = json['rangeMax'];
    final target = json['target'];
    final attemptsUsed = json['attemptsUsed'] ?? 0;
    final correctGuesses = json['correctGuesses'] ?? 0;
    final hintsUsed = json['hintsUsed'] ?? 0;
    final completed = json['completed'] ?? false;
    if (runId is! String ||
        rangeMin is! int ||
        rangeMax is! int ||
        target is! int ||
        attemptsUsed is! int ||
        correctGuesses is! int ||
        hintsUsed is! int ||
        completed is! bool) {
      throw const FormatException('Invalid creative-mode run snapshot.');
    }
    return CreativeModeRunSnapshot(
      runId: runId,
      rangeMin: rangeMin,
      rangeMax: rangeMax,
      target: target,
      attemptsUsed: attemptsUsed,
      correctGuesses: correctGuesses,
      hintsUsed: hintsUsed,
      completed: completed,
    );
  }
}

class CreativeModeSave {
  const CreativeModeSave({
    this.schemaVersion = currentSchemaVersion,
    this.name = 'My Creative Mode',
    this.enabled = false,
    this.rangeMin = 1,
    this.rangeMax = 100,
    this.effects = const [],
    this.activeRun,
  });

  static const currentSchemaVersion = 3;
  static const maxEffects = 16;
  static const maxRange = 1000000;

  final int schemaVersion;
  final String name;
  final bool enabled;
  final int rangeMin;
  final int rangeMax;
  final List<CreativeModeEffect> effects;
  final CreativeModeRunSnapshot? activeRun;

  CreativeModeSave copyWith({
    String? name,
    bool? enabled,
    int? rangeMin,
    int? rangeMax,
    List<CreativeModeEffect>? effects,
    CreativeModeRunSnapshot? activeRun,
    bool clearActiveRun = false,
  }) =>
      CreativeModeSave(
        schemaVersion: schemaVersion,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        rangeMin: rangeMin ?? this.rangeMin,
        rangeMax: rangeMax ?? this.rangeMax,
        effects: effects ?? this.effects,
        activeRun: clearActiveRun ? null : activeRun ?? this.activeRun,
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'name': name,
        'enabled': enabled,
        'rangeMin': rangeMin,
        'rangeMax': rangeMax,
        'effects': effects.map((effect) => effect.toJson()).toList(),
        'activeRun': activeRun?.toJson(),
      };

  static bool validate(CreativeModeSave save) {
    if (save.schemaVersion != currentSchemaVersion ||
        save.name.trim().isEmpty ||
        save.name.length > 40 ||
        save.rangeMin < 1 ||
        save.rangeMax < save.rangeMin ||
        save.rangeMax > maxRange ||
        save.effects.length > maxEffects ||
        save.effects.map((effect) => effect.id).toSet().length !=
            save.effects.length) {
      return false;
    }
    if (save.activeRun != null && !validateRunSnapshot(save.activeRun!)) {
      return false;
    }
    return save.effects.every((effect) {
      if (!RegExp(r'^[a-z][a-z0-9_-]{1,31}$').hasMatch(effect.id)) {
        return false;
      }
      return switch (effect.type) {
        CreativeEffectType.rangeScale => effect.value >= 1 && effect.value <= 5,
        CreativeEffectType.extraHints => effect.value >= 0 && effect.value <= 5,
        CreativeEffectType.attemptLimit =>
          effect.value >= 1 && effect.value <= 100,
      };
    });
  }

  static bool validateRunSnapshot(CreativeModeRunSnapshot run) =>
      RegExp(r'^[a-zA-Z0-9_-]{8,64}$').hasMatch(run.runId) &&
      run.rangeMin >= 1 &&
      run.rangeMax >= run.rangeMin &&
      run.rangeMax <= maxRange &&
      run.target >= run.rangeMin &&
      run.target <= run.rangeMax &&
      run.attemptsUsed >= 0 &&
      run.correctGuesses >= 0 &&
      run.correctGuesses <= run.attemptsUsed &&
      run.hintsUsed >= 0 &&
      run.hintsUsed <= 10 &&
      (!run.completed ||
          (run.attemptsUsed > 0 && run.correctGuesses > 0));

  static String encode(CreativeModeSave save) {
    if (!validate(save)) {
      throw ArgumentError('Invalid creative-mode save.');
    }
    return jsonEncode(save.toJson());
  }

  static CreativeModeSave? decodeAndMigrate(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final version = decoded['schemaVersion'];
      if (version is! int || version < 1 || version > currentSchemaVersion) {
        return null;
      }
      final name = decoded['name'] ?? 'My Creative Mode';
      final enabled = decoded['enabled'] ?? false;
      final rangeMin = decoded['rangeMin'] ?? 1;
      final rangeMax = decoded['rangeMax'] ?? 100;
      final effectsJson = decoded['effects'] ?? const [];
      if (name is! String ||
          enabled is! bool ||
          rangeMin is! int ||
          rangeMax is! int ||
          effectsJson is! List) {
        return null;
      }
      final effects = version == 1
          ? <CreativeModeEffect>[]
          : effectsJson
              .map((item) => item is Map<String, dynamic>
                  ? CreativeModeEffect.fromJson(item)
                  : throw const FormatException('Invalid creative-mode effect.'))
              .toList();
      final activeRunJson = decoded['activeRun'];
      final migrated = CreativeModeSave(
        schemaVersion: currentSchemaVersion,
        name: name,
        enabled: enabled,
        rangeMin: rangeMin,
        rangeMax: rangeMax,
        effects: effects,
        activeRun: version < 3
            ? null
            : activeRunJson == null
                ? null
                : activeRunJson is Map<String, dynamic>
                    ? CreativeModeRunSnapshot.fromJson(activeRunJson)
                    : throw const FormatException('Invalid active creative run.'),
      );
      return validate(migrated) ? migrated : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

class CreativeRuntimeRules {
  const CreativeRuntimeRules({
    required this.rangeMin,
    required this.rangeMax,
    required this.extraHints,
    required this.attemptLimit,
  });

  final int rangeMin;
  final int rangeMax;
  final int extraHints;
  final int? attemptLimit;
}

class CreativeModeEffectPolicy {
  static CreativeRuntimeRules? resolve(CreativeModeSave save) {
    if (!CreativeModeSave.validate(save)) return null;
    final minimum = save.rangeMin;
    var maximum = save.rangeMax;
    var hints = 0;
    int? attempts;
    if (save.enabled) {
      for (final effect in save.effects) {
        switch (effect.type) {
          case CreativeEffectType.rangeScale:
            final width = (maximum - minimum + 1)
                .clamp(1, CreativeModeSave.maxRange)
                .toInt();
            final scaled = (width * effect.value)
                .clamp(1, CreativeModeSave.maxRange)
                .toInt();
            maximum = (minimum + scaled - 1)
                .clamp(minimum, CreativeModeSave.maxRange)
                .toInt();
            break;
          case CreativeEffectType.extraHints:
            hints = (hints + effect.value).clamp(0, 10).toInt();
            break;
          case CreativeEffectType.attemptLimit:
            attempts = attempts == null || attempts > effect.value
                ? effect.value
                : attempts;
            break;
        }
      }
    }
    return CreativeRuntimeRules(
      rangeMin: minimum,
      rangeMax: maximum,
      extraHints: hints,
      attemptLimit: attempts,
    );
  }
}

class CreativeModeRun {
  const CreativeModeRun({
    required this.runId,
    required this.rangeMin,
    required this.rangeMax,
    required this.target,
    this.attemptsUsed = 0,
    this.correctGuesses = 0,
    this.hintsUsed = 0,
    this.completed = false,
  });

  final String runId;
  final int rangeMin;
  final int rangeMax;
  final int target;
  final int attemptsUsed;
  final int correctGuesses;
  final int hintsUsed;
  final bool completed;

  CreativeModeRun copyWith({
    int? attemptsUsed,
    int? correctGuesses,
    int? hintsUsed,
    bool? completed,
  }) =>
      CreativeModeRun(
        runId: runId,
        rangeMin: rangeMin,
        rangeMax: rangeMax,
        target: target,
        attemptsUsed: attemptsUsed ?? this.attemptsUsed,
        correctGuesses: correctGuesses ?? this.correctGuesses,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        completed: completed ?? this.completed,
      );

  CreativeModeRunSnapshot toSnapshot() => CreativeModeRunSnapshot(
        runId: runId,
        rangeMin: rangeMin,
        rangeMax: rangeMax,
        target: target,
        attemptsUsed: attemptsUsed,
        correctGuesses: correctGuesses,
        hintsUsed: hintsUsed,
        completed: completed,
      );
}

class CreativeGuessDecision {
  const CreativeGuessDecision({
    required this.outcome,
    required this.run,
    required this.accepted,
  });

  final CreativeGuessOutcome outcome;
  final CreativeModeRun run;
  final bool accepted;
}

class CreativeModeRuntime {
  static CreativeModeRun? start(CreativeModeSave save, int target) {
    final rules = CreativeModeEffectPolicy.resolve(save);
    if (rules == null ||
        !save.enabled ||
        target < rules.rangeMin ||
        target > rules.rangeMax) {
      return null;
    }
    final random = Random.secure();
    final runId = List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return CreativeModeRun(
      runId: runId,
      rangeMin: rules.rangeMin,
      rangeMax: rules.rangeMax,
      target: target,
    );
  }

  static CreativeModeRun? resume(CreativeModeSave save) {
    final snapshot = save.activeRun;
    final rules = CreativeModeEffectPolicy.resolve(save);
    if (snapshot == null ||
        rules == null ||
        !save.enabled ||
        !CreativeModeSave.validateRunSnapshot(snapshot) ||
        snapshot.rangeMin != rules.rangeMin ||
        snapshot.rangeMax != rules.rangeMax ||
        snapshot.hintsUsed > rules.extraHints ||
        (rules.attemptLimit != null &&
            snapshot.attemptsUsed > rules.attemptLimit!)) {
      return null;
    }
    return CreativeModeRun(
      runId: snapshot.runId,
      rangeMin: snapshot.rangeMin,
      rangeMax: snapshot.rangeMax,
      target: snapshot.target,
      attemptsUsed: snapshot.attemptsUsed,
      correctGuesses: snapshot.correctGuesses,
      hintsUsed: snapshot.hintsUsed,
      completed: snapshot.completed,
    );
  }

  static CreativeModeSave? persist(
    CreativeModeSave save,
    CreativeModeRun run,
  ) {
    if (!_matchesRules(save, run)) return null;
    return save.copyWith(activeRun: run.toSnapshot());
  }

  static CreativeModeSave clearPersistedRun(CreativeModeSave save) =>
      save.copyWith(clearActiveRun: true);

  static bool _matchesRules(CreativeModeSave save, CreativeModeRun run) {
    final rules = CreativeModeEffectPolicy.resolve(save);
    return save.enabled &&
        rules != null &&
        CreativeModeSave.validateRunSnapshot(run.toSnapshot()) &&
        run.rangeMin == rules.rangeMin &&
        run.rangeMax == rules.rangeMax &&
        run.hintsUsed <= rules.extraHints &&
        (rules.attemptLimit == null ||
            run.attemptsUsed <= rules.attemptLimit!);
  }

  static CreativeGuessDecision submitGuess(
    CreativeModeSave save,
    CreativeModeRun run,
    int guess,
  ) {
    final rules = CreativeModeEffectPolicy.resolve(save);
    if (rules == null) {
      return CreativeGuessDecision(
        outcome: CreativeGuessOutcome.invalidConfiguration,
        run: run,
        accepted: false,
      );
    }
    if (!save.enabled || run.completed) {
      return CreativeGuessDecision(
        outcome: CreativeGuessOutcome.completed,
        run: run,
        accepted: false,
      );
    }
    if (!_matchesRules(save, run)) {
      return CreativeGuessDecision(
        outcome: CreativeGuessOutcome.invalidConfiguration,
        run: run,
        accepted: false,
      );
    }
    if (guess < run.rangeMin || guess > run.rangeMax) {
      return CreativeGuessDecision(
        outcome: CreativeGuessOutcome.outOfRange,
        run: run,
        accepted: false,
      );
    }
    if (rules.attemptLimit != null &&
        run.attemptsUsed >= rules.attemptLimit!) {
      return CreativeGuessDecision(
        outcome: CreativeGuessOutcome.attemptLimit,
        run: run,
        accepted: false,
      );
    }
    final nextAttempts = run.attemptsUsed + 1;
    if (guess < run.target) {
      return CreativeGuessDecision(
        outcome: CreativeGuessOutcome.tooLow,
        run: run.copyWith(attemptsUsed: nextAttempts),
        accepted: true,
      );
    }
    if (guess > run.target) {
      return CreativeGuessDecision(
        outcome: CreativeGuessOutcome.tooHigh,
        run: run.copyWith(attemptsUsed: nextAttempts),
        accepted: true,
      );
    }
    return CreativeGuessDecision(
      outcome: CreativeGuessOutcome.correct,
      run: run.copyWith(
        attemptsUsed: nextAttempts,
        correctGuesses: run.correctGuesses + 1,
        completed: true,
      ),
      accepted: true,
    );
  }

  static CreativeModeRun? useHint(
    CreativeModeSave save,
    CreativeModeRun run,
  ) {
    final rules = CreativeModeEffectPolicy.resolve(save);
    if (rules == null ||
        !save.enabled ||
        !_matchesRules(save, run) ||
        run.completed ||
        run.hintsUsed >= rules.extraHints) {
      return null;
    }
    return run.copyWith(hintsUsed: run.hintsUsed + 1);
  }
}
