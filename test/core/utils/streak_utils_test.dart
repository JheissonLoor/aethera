import 'package:aethera/core/utils/streak_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('streak utils', () {
    test('dayKey uses zero-padded month/day', () {
      final key = dayKey(DateTime(2026, 3, 9));
      expect(key, '2026-03-09');
    });

    test('shouldIncrementStreakToday is false if already counted today', () {
      const today = '2026-03-10';
      final shouldIncrement = shouldIncrementStreakToday(
        lastStreakDate: today,
        user1CheckinDate: today,
        user2CheckinDate: today,
        todayKey: today,
      );

      expect(shouldIncrement, isFalse);
    });

    test(
      'shouldIncrementStreakToday is false when only one user checked in',
      () {
        const today = '2026-03-10';
        final shouldIncrement = shouldIncrementStreakToday(
          lastStreakDate: '2026-03-09',
          user1CheckinDate: today,
          user2CheckinDate: null,
          todayKey: today,
        );

        expect(shouldIncrement, isFalse);
      },
    );

    test('shouldIncrementStreakToday is true when both checked in today', () {
      const today = '2026-03-10';
      final shouldIncrement = shouldIncrementStreakToday(
        lastStreakDate: '2026-03-09',
        user1CheckinDate: today,
        user2CheckinDate: today,
        todayKey: today,
      );

      expect(shouldIncrement, isTrue);
    });

    test(
      'nextStreakValue increments only when previous streak date is yesterday',
      () {
        final incremented = nextStreakValue(
          lastStreakDate: '2026-03-09',
          currentStreak: 7,
          yesterdayKey: '2026-03-09',
        );
        final reset = nextStreakValue(
          lastStreakDate: '2026-03-07',
          currentStreak: 7,
          yesterdayKey: '2026-03-09',
        );

        expect(incremented, 8);
        expect(reset, 1);
      },
    );
  });
}
