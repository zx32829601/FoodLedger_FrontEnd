import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/localization/localization_providers.dart';
import 'package:food_ledger_frontend/features/home/presentation/providers/home_providers.dart';
import 'package:food_ledger_frontend/features/records/data/mock_daily_record_repository.dart';
import 'package:food_ledger_frontend/features/records/data/mock_nutrition_repository.dart';
import 'package:food_ledger_frontend/features/records/domain/models/daily_record.dart';
import 'package:food_ledger_frontend/features/records/presentation/providers/record_providers.dart';

void main() {
  test('首頁資料重新載入時固定查詢今天，不受紀錄頁選取日期影響', () async {
    final today = DateTime(2026, 7, 28);
    final now = DateTime.utc(2026, 7, 27, 16, 30);
    final repository = _RecordingDailyRecordRepository();
    final container = ProviderContainer(
      overrides: [
        homeNowProvider.overrideWithValue(() => now),
        dailyRecordRepositoryProvider.overrideWithValue(repository),
        nutritionRepositoryProvider.overrideWithValue(
          MockNutritionRepository(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(selectedDateProvider.notifier)
        .select(DateTime(2025, 12, 15));

    await container.read(homeDailyRecordsProvider.future);
    final firstSummary = await container.read(
      homeNutritionSummaryProvider.future,
    );

    container.read(selectedDateProvider.notifier).select(DateTime(2027, 1, 10));
    container.invalidate(homeDailyRecordsProvider);

    await container.read(homeDailyRecordsProvider.future);
    final refreshedSummary = await container.read(
      homeNutritionSummaryProvider.future,
    );

    expect(repository.requestedDates, isNotEmpty);
    expect(
      repository.requestedDates.every((date) => _isSameDate(date, today)),
      isTrue,
    );
    expect(firstSummary.date, today);
    expect(refreshedSummary.date, today);
  });

  test('首頁今天依 IANA 時區計算，跨日後可重新整理', () {
    var now = DateTime.utc(2026, 7, 28, 1);
    final container = ProviderContainer(
      overrides: [homeNowProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);

    container
        .read(nutritionTimeZoneProvider.notifier)
        .select('America/New_York');

    expect(container.read(homeTodayProvider), DateTime(2026, 7, 27));

    now = DateTime.utc(2026, 7, 28, 5);
    container.read(homeTodayProvider.notifier).refresh();

    expect(container.read(homeTodayProvider), DateTime(2026, 7, 28));
  });
}

class _RecordingDailyRecordRepository extends MockDailyRecordRepository {
  _RecordingDailyRecordRepository() : super(initialRecords: []);

  final requestedDates = <DateTime>[];

  @override
  Future<List<DailyRecord>> getRecordsForDate(
    DateTime date, {
    required String timeZone,
    required String langCode,
  }) {
    requestedDates.add(date);
    return super.getRecordsForDate(
      date,
      timeZone: timeZone,
      langCode: langCode,
    );
  }
}

bool _isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
