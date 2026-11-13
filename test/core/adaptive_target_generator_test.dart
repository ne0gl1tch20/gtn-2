import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/adaptive_target_generator.dart';

void main() {
  group('AdaptiveTargetGenerator', () {
    test('matches the GTN1 native/Kotlin reference vectors', () {
      expect(
        AdaptiveTargetGenerator.nextTarget(
          rangeMin: 1,
          rangeMax: 100,
          difficultyId: 'classic',
          streak: 0,
          attempts: 0,
          seed: BigInt.zero,
        ),
        82,
      );
      expect(
        AdaptiveTargetGenerator.nextTarget(
          rangeMin: 1,
          rangeMax: 100,
          difficultyId: 'classic',
          streak: 7,
          attempts: 3,
          seed: BigInt.from(0x1234ABCD),
        ),
        63,
      );
      expect(
        AdaptiveTargetGenerator.nextTarget(
          rangeMin: 1,
          rangeMax: 150,
          difficultyId: 'hard',
          streak: 7,
          attempts: 3,
          seed: BigInt.from(0x1234ABCD),
        ),
        150,
      );
      expect(
        AdaptiveTargetGenerator.nextTarget(
          rangeMin: 1,
          rangeMax: 250,
          difficultyId: 'extreme',
          streak: 12,
          attempts: 44,
          seed: BigInt.parse('DEADBEEFCAFEBABE', radix: 16),
        ),
        219,
      );
    });

    test('matches the 128-case GTN1 reference checksum', () {
      var checksum = 0;
      for (var index = 0; index < 128; index++) {
        final difficultyId = switch (index % 3) {
          0 => 'classic',
          1 => 'hard',
          _ => 'extreme',
        };
        final rangeMin = 1;
        final rangeMax = 1000 + (index % 4) * 9000;
        final result = AdaptiveTargetGenerator.nextTarget(
          rangeMin: rangeMin,
          rangeMax: rangeMax,
          difficultyId: difficultyId,
          streak: index % 41,
          attempts: (index * 17) % 500,
          seed: BigInt.from(0x1234ABCD + index * 0x9E37),
        );
        expect(result, inInclusiveRange(rangeMin, rangeMax));
        checksum ^= result;
      }
      expect(checksum, 20652);
    });

    test('normalizes negative seeds as unsigned 64-bit values', () {
      final fromNegativeSeed = AdaptiveTargetGenerator.nextTarget(
        rangeMin: 1,
        rangeMax: 1000,
        difficultyId: 'hard',
        streak: 4,
        attempts: 12,
        seed: BigInt.from(-1),
      );
      final fromUnsignedSeed = AdaptiveTargetGenerator.nextTarget(
        rangeMin: 1,
        rangeMax: 1000,
        difficultyId: 'hard',
        streak: 4,
        attempts: 12,
        seed: (BigInt.one << 64) - BigInt.one,
      );
      expect(fromNegativeSeed, fromUnsignedSeed);
    });

    test('keeps degenerate and invalid ranges bounded', () {
      expect(
        AdaptiveTargetGenerator.nextTarget(
          rangeMin: 8,
          rangeMax: 8,
          difficultyId: 'classic',
          streak: 0,
          attempts: 0,
          seed: BigInt.zero,
        ),
        8,
      );
      expect(
        AdaptiveTargetGenerator.nextTarget(
          rangeMin: 9,
          rangeMax: 4,
          difficultyId: 'classic',
          streak: 0,
          attempts: 0,
          seed: BigInt.zero,
        ),
        9,
      );
    });

    test('creates full-width random seeds', () {
      final seed = AdaptiveTargetGenerator.randomSeed(Random(1234));
      expect(seed, greaterThanOrEqualTo(BigInt.zero));
      expect(seed, lessThan(BigInt.one << 64));
    });
  });
}
