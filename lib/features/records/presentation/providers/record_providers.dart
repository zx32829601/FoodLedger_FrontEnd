import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/api_daily_record_repository.dart';
import '../../data/api_food_repository.dart';
import '../../data/api_nutrition_repository.dart';
import '../../domain/models/daily_record.dart';
import '../../domain/models/food.dart';
import '../../domain/models/meal_type.dart';
import '../../domain/models/nutrition_summary.dart';
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

class SelectedDateController extends Notifier<DateTime> {
  @override
  DateTime build() => _dateOnly(DateTime.now());

  void previousDay() {
    state = _dateOnly(state.subtract(const Duration(days: 1)));
  }

  void nextDay() {
    state = _dateOnly(state.add(const Duration(days: 1)));
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
    return ref
        .watch(dailyRecordRepositoryProvider)
        .getRecordsForDate(selectedDate);
  }

  Future<void> addRecord({
    required Food food,
    required double quantityGrams,
    required MealType mealType,
    String? note,
  }) async {
    final selectedDate = ref.read(selectedDateProvider);
    final localConsumedAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
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
      return ref
          .read(dailyRecordRepositoryProvider)
          .getRecordsForDate(selectedDate);
    });
  }

  Future<void> deleteRecord(int recordId) async {
    final selectedDate = ref.read(selectedDateProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(dailyRecordRepositoryProvider).deleteRecord(recordId);
      return ref
          .read(dailyRecordRepositoryProvider)
          .getRecordsForDate(selectedDate);
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
      return ref
          .read(dailyRecordRepositoryProvider)
          .getRecordsForDate(selectedDate);
    });
  }
}

final dailyRecordsProvider =
    AsyncNotifierProvider<DailyRecordsController, List<DailyRecord>>(
      DailyRecordsController.new,
    );

final nutritionSummaryProvider = FutureProvider<NutritionSummary>((ref) async {
  await ref.watch(dailyRecordsProvider.future);
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(nutritionRepositoryProvider).getSummaryForDate(selectedDate);
});

final foodSearchProvider = FutureProvider.family<List<Food>, String>((
  ref,
  query,
) {
  return ref.watch(foodRepositoryProvider).searchFoods(query: query);
});
