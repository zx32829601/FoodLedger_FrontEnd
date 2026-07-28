import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_providers.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/api_daily_record_repository.dart';
import '../../data/api_food_repository.dart';
import '../../data/api_nutrition_repository.dart';
import '../../domain/models/daily_record.dart';
import '../../domain/models/food.dart';
import '../../domain/models/meal_type.dart';
import '../../domain/models/nutrition_summary.dart';
import '../../domain/models/weekly_nutrition_summary.dart';
import '../../domain/repositories/daily_record_repository.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/nutrition_repository.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return ApiFoodRepository(ref.watch(apiClientProvider).dio);
});

final dailyRecordRepositoryProvider = Provider<DailyRecordRepository>((ref) {
  return ApiDailyRecordRepository(ref.watch(apiClientProvider).dio);
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return ApiNutritionRepository(ref.watch(apiClientProvider).dio);
});

typedef LocalizedDateQuery = ({
  DateTime date,
  String timeZone,
  String langCode,
});

/// 集中組合飲食紀錄與營養摘要共用的日期、時區及語系查詢條件。
final localizedDateQueryProvider =
    Provider.family<LocalizedDateQuery, DateTime>((ref, date) {
      return (
        date: date,
        timeZone: ref.watch(nutritionTimeZoneProvider),
        langCode: ref.watch(nutritionLangCodeProvider),
      );
    });

class SelectedDateController extends Notifier<DateTime> {
  @override
  DateTime build() => _dateOnly(DateTime.now());

  void previousDay() {
    state = _dateOnly(state.subtract(const Duration(days: 1)));
  }

  void nextDay() {
    state = _dateOnly(state.add(const Duration(days: 1)));
  }

  void previousWeek() {
    state = _dateOnly(state.subtract(const Duration(days: 7)));
  }

  void nextWeek() {
    state = _dateOnly(state.add(const Duration(days: 7)));
  }

  void select(DateTime date) {
    state = _dateOnly(date);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateController, DateTime>(
  SelectedDateController.new,
);

class DailyRecordsController extends AsyncNotifier<List<DailyRecord>> {
  @override
  Future<List<DailyRecord>> build() {
    final selectedDate = ref.watch(selectedDateProvider);
    final query = ref.watch(localizedDateQueryProvider(selectedDate));
    return _loadRecords(
      query.date,
      ref.watch(dailyRecordRepositoryProvider),
      timeZone: query.timeZone,
      langCode: query.langCode,
    );
  }

  /// 新增飲食紀錄；未指定 [recordDate] 時沿用飲食紀錄頁目前選取的日期。
  Future<void> addRecord({
    required Food food,
    required double quantityGrams,
    required MealType mealType,
    String? note,
    DateTime? recordDate,
  }) async {
    final selectedDate = ref.read(selectedDateProvider);
    final selectedDateQuery = ref.read(
      localizedDateQueryProvider(selectedDate),
    );
    final targetDate = recordDate == null
        ? selectedDate
        : DateTime(recordDate.year, recordDate.month, recordDate.day);
    final existingRecords = state.value ?? const <DailyRecord>[];
    final localConsumedAt = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      mealType.defaultHour,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(dailyRecordRepositoryProvider)
          .addRecord(
            food: food,
            quantityGrams: quantityGrams,
            consumedAt: localConsumedAt,
            mealTypeCode: mealType.code,
            note: note,
          );
      try {
        return await _loadRecords(
          selectedDateQuery.date,
          ref.read(dailyRecordRepositoryProvider),
          timeZone: selectedDateQuery.timeZone,
          langCode: selectedDateQuery.langCode,
        );
      } on Exception {
        return existingRecords;
      }
    });
  }

  Future<void> deleteRecord(int recordId) async {
    final selectedDate = ref.read(selectedDateProvider);
    final query = ref.read(localizedDateQueryProvider(selectedDate));
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(dailyRecordRepositoryProvider).deleteRecord(recordId);
      return _loadRecords(
        query.date,
        ref.read(dailyRecordRepositoryProvider),
        timeZone: query.timeZone,
        langCode: query.langCode,
      );
    });
  }

  Future<void> updateRecord({
    required DailyRecord record,
    required Food food,
    required double quantityGrams,
    required MealType mealType,
    String? note,
  }) async {
    final selectedDate = ref.read(selectedDateProvider);
    final query = ref.read(localizedDateQueryProvider(selectedDate));
    state = await AsyncValue.guard(() async {
      await ref
          .read(dailyRecordRepositoryProvider)
          .updateRecord(
            recordId: record.id,
            food: food,
            quantityGrams: quantityGrams,
            consumedAt: record.consumedAt,
            mealTypeCode: mealType.code,
            note: note,
          );
      return _loadRecords(
        query.date,
        ref.read(dailyRecordRepositoryProvider),
        timeZone: query.timeZone,
        langCode: query.langCode,
      );
    });
  }

  Future<List<DailyRecord>> _loadRecords(
    DateTime date,
    DailyRecordRepository repository, {
    required String timeZone,
    required String langCode,
  }) {
    return repository.getRecordsForDate(
      date,
      timeZone: timeZone,
      langCode: langCode,
    );
  }
}

final dailyRecordsProvider =
    AsyncNotifierProvider<DailyRecordsController, List<DailyRecord>>(
      DailyRecordsController.new,
    );

final nutritionSummaryProvider = FutureProvider<NutritionSummary>((ref) async {
  await ref.watch(dailyRecordsProvider.future);
  final selectedDate = ref.watch(selectedDateProvider);
  final query = ref.watch(localizedDateQueryProvider(selectedDate));
  return ref
      .watch(nutritionRepositoryProvider)
      .getDailySummary(
        date: query.date,
        timeZone: query.timeZone,
        langCode: query.langCode,
      );
});

final weeklyNutritionSummaryProvider = FutureProvider<WeeklyNutritionSummary>((
  ref,
) async {
  await ref.watch(dailyRecordsProvider.future);
  final query = ref.watch(
    localizedDateQueryProvider(ref.watch(selectedDateProvider)),
  );
  return ref
      .watch(nutritionRepositoryProvider)
      .getWeeklySummary(
        date: query.date,
        timeZone: query.timeZone,
        langCode: query.langCode,
      );
});

final foodSearchProvider = FutureProvider.family<List<Food>, String>((
  ref,
  query,
) {
  return ref
      .watch(foodRepositoryProvider)
      .searchFoods(
        query: query,
        langCode: ref.watch(nutritionLangCodeProvider),
      );
});
