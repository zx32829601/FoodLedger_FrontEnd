import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_daily_record_repository.dart';
import '../../data/mock_food_repository.dart';
import '../../data/mock_nutrition_repository.dart';
import '../../domain/models/daily_record.dart';
import '../../domain/models/food.dart';
import '../../domain/models/meal_type.dart';
import '../../domain/models/nutrition_summary.dart';
import '../../domain/repositories/daily_record_repository.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/nutrition_repository.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return MockFoodRepository();
});

final dailyRecordRepositoryProvider = Provider<DailyRecordRepository>((ref) {
  return MockDailyRecordRepository();
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return MockNutritionRepository(ref.watch(dailyRecordRepositoryProvider));
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
