import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/iana_local_date.dart';
import '../../../../core/localization/localization_providers.dart';
import '../../../records/domain/models/daily_record.dart';
import '../../../records/domain/models/nutrition_summary.dart';
import '../../../records/presentation/providers/record_providers.dart';

typedef HomeClock = DateTime Function();

/// 提供可替換的目前時間，讓跨時區與跨日行為能以固定時間驗證。
final homeNowProvider = Provider<HomeClock>((ref) => DateTime.now);

/// 管理首頁在 Nutrition API IANA 時區中的「今天」。
class HomeTodayController extends Notifier<DateTime> {
  Timer? _nextDayTimer;

  @override
  DateTime build() {
    final timeZone = ref.watch(nutritionTimeZoneProvider);
    ref.onDispose(() => _nextDayTimer?.cancel());
    return _readTodayAndSchedule(timeZone);
  }

  /// 回到前景或測試跨日後，立即重新計算首頁日期。
  void refresh() {
    state = _readTodayAndSchedule(ref.read(nutritionTimeZoneProvider));
  }

  DateTime _readTodayAndSchedule(String timeZone) {
    _nextDayTimer?.cancel();
    final now = ref.read(homeNowProvider)();
    final today = localDateInTimeZone(now, timeZone);
    final untilNextDay = durationUntilNextLocalDay(now, timeZone);
    final delay = untilNextDay.isNegative || untilNextDay == Duration.zero
        ? const Duration(seconds: 1)
        : untilNextDay + const Duration(milliseconds: 100);
    _nextDayTimer = Timer(delay, refresh);
    return today;
  }
}

final homeTodayProvider = NotifierProvider<HomeTodayController, DateTime>(
  HomeTodayController.new,
);

/// 載入首頁「今日飲食」，不依賴飲食紀錄頁選取的日期。
final homeDailyRecordsProvider = FutureProvider<List<DailyRecord>>((ref) {
  final query = ref.watch(
    localizedDateQueryProvider(ref.watch(homeTodayProvider)),
  );
  return ref
      .watch(dailyRecordRepositoryProvider)
      .getRecordsForDate(
        query.date,
        timeZone: query.timeZone,
        langCode: query.langCode,
      );
});

/// 載入首頁今日營養摘要，並在今日飲食重新整理後同步更新。
final homeNutritionSummaryProvider = FutureProvider<NutritionSummary>((
  ref,
) async {
  await ref.watch(homeDailyRecordsProvider.future);
  final query = ref.watch(
    localizedDateQueryProvider(ref.watch(homeTodayProvider)),
  );
  return ref
      .watch(nutritionRepositoryProvider)
      .getDailySummary(
        date: query.date,
        timeZone: query.timeZone,
        langCode: query.langCode,
      );
});
