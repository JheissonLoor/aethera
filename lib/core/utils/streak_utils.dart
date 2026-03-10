String dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

bool shouldIncrementStreakToday({
  required String? lastStreakDate,
  required String? user1CheckinDate,
  required String? user2CheckinDate,
  required String todayKey,
}) {
  if (lastStreakDate == todayKey) return false;
  return user1CheckinDate == todayKey && user2CheckinDate == todayKey;
}

int nextStreakValue({
  required String? lastStreakDate,
  required int currentStreak,
  required String yesterdayKey,
}) {
  if (lastStreakDate == yesterdayKey) return currentStreak + 1;
  return 1;
}
