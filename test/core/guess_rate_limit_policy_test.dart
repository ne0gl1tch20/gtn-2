import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/guess_rate_limit_policy.dart';

void main() {
  group('GuessRateLimitPolicy', () {
    test('allows the first submission', () {
      expect(
        GuessRateLimitPolicy.isRateLimited(
          lastSubmissionMicroseconds: null,
          nowMicroseconds: 100,
        ),
        isFalse,
      );
    });

    test('blocks submissions before the 50 ms interval', () {
      expect(
        GuessRateLimitPolicy.isRateLimited(
          lastSubmissionMicroseconds: 100000,
          nowMicroseconds: 149999,
        ),
        isTrue,
      );
    });

    test('allows a submission exactly at the 50 ms boundary', () {
      expect(
        GuessRateLimitPolicy.isRateLimited(
          lastSubmissionMicroseconds: 100000,
          nowMicroseconds: 150000,
        ),
        isFalse,
      );
    });

    test('treats a backwards monotonic timestamp as rate-limited', () {
      expect(
        GuessRateLimitPolicy.isRateLimited(
          lastSubmissionMicroseconds: 100000,
          nowMicroseconds: 99999,
        ),
        isTrue,
      );
    });

    test('a non-positive interval disables the limit', () {
      expect(
        GuessRateLimitPolicy.isRateLimited(
          lastSubmissionMicroseconds: 100000,
          nowMicroseconds: 100001,
          minimumInterval: 0,
        ),
        isFalse,
      );
    });
  });

  group('GuessRateLimiter', () {
    test('rejected submissions do not reset the accepted timestamp', () {
      var now = 100000;
      final limiter = GuessRateLimiter(nowMicroseconds: () => now);

      expect(limiter.tryAccept(), isTrue);
      now = 149999;
      expect(limiter.tryAccept(), isFalse);
      now = 150000;
      expect(limiter.tryAccept(), isTrue);
    });

    test('uses an independent timestamp per limiter', () {
      var now = 100000;
      final first = GuessRateLimiter(nowMicroseconds: () => now);
      final second = GuessRateLimiter(nowMicroseconds: () => now);

      expect(first.tryAccept(), isTrue);
      expect(first.tryAccept(), isFalse);
      expect(second.tryAccept(), isTrue);
    });
  });
}
