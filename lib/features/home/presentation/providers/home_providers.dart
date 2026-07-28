import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_providers.dart';
import '../../../records/domain/models/daily_record.dart';
import '../../../records/domain/models/nutrition_summary.dart';
import '../../../records/presentation/providers/record_providers.dart';

/// 首頁固定使用的本地日期，可在測試或未來時鐘服務中替換。
final homeTodayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 載入首頁「今日飲食」，不依賴飲食紀錄頁選取的日期。
final homeDailyRecordsProvider = FutureProvider<List<DailyRecord>>((ref) {
  return ref
      .watch(dailyRecordRepositoryProvider)
      .getRecordsForDate(
        ref.watch(homeTodayProvider),
        timeZone: ref.watch(nutritionTimeZoneProvider),
        langCode: ref.watch(nutritionLangCodeProvider),
      );
});

/// 載入首頁今日營養摘要，並在今日飲食重新整理後同步更新。
final homeNutritionSummaryProvider = FutureProvider<NutritionSummary>((
  ref,
) async {
  await ref.watch(homeDailyRecordsProvider.future);
  return ref
      .watch(nutritionRepositoryProvider)
      .getDailySummary(
        date: ref.watch(homeTodayProvider),
        timeZone: ref.watch(nutritionTimeZoneProvider),
        langCode: ref.watch(nutritionLangCodeProvider),
      );
});
