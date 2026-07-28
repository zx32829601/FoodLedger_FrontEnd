import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/localization/localization_providers.dart';
import 'package:food_ledger_frontend/features/records/data/mock_daily_record_repository.dart';
import 'package:food_ledger_frontend/features/records/data/mock_foods.dart';
import 'package:food_ledger_frontend/features/records/data/mock_nutrition_repository.dart';
import 'package:food_ledger_frontend/features/records/domain/models/daily_record.dart';
import 'package:food_ledger_frontend/features/records/domain/models/food.dart';
import 'package:food_ledger_frontend/features/records/domain/models/meal_type.dart';
import 'package:food_ledger_frontend/features/records/domain/repositories/food_repository.dart';
import 'package:food_ledger_frontend/features/records/presentation/providers/record_providers.dart';

void main() {
  test('DailyRecordsController_AddRecord_UpdatesRecordsAndSummary', () async {
    final repository = MockDailyRecordRepository(initialRecords: []);
    final container = ProviderContainer(
      overrides: [
        dailyRecordRepositoryProvider.overrideWithValue(repository),
        nutritionRepositoryProvider.overrideWithValue(
          MockNutritionRepository(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(dailyRecordsProvider.future), isEmpty);

    await container
        .read(dailyRecordsProvider.notifier)
        .addRecord(
          food: mockFoods[1],
          quantityGrams: 100,
          mealType: MealType.lunch,
          note: '公司午餐',
        );
    final records = await container.read(dailyRecordsProvider.future);
    final summary = await container.read(nutritionSummaryProvider.future);

    expect(records, hasLength(1));
    expect(records.single.mealType, MealType.lunch);
    expect(records.single.note, '公司午餐');
    expect(summary.nutrient('Calories')?.amount, closeTo(165, 0.001));
    expect(summary.nutrient('Protein')?.amount, closeTo(31, 0.001));
  });

  test(
    'LocalizationSettings_WhenChanged_ReloadLocalizedRepositories',
    () async {
      final dailyRepository = _RecordingDailyRecordRepository();
      final foodRepository = _RecordingFoodRepository();
      final container = ProviderContainer(
        overrides: [
          dailyRecordRepositoryProvider.overrideWithValue(dailyRepository),
          foodRepositoryProvider.overrideWithValue(foodRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(dailyRecordsProvider.future);
      await container.read(foodSearchProvider('tofu').future);

      container.read(nutritionLangCodeProvider.notifier).select('en-US');
      container
          .read(nutritionTimeZoneProvider.notifier)
          .select('America/New_York');

      await container.read(dailyRecordsProvider.future);
      await container.read(foodSearchProvider('tofu').future);

      expect(dailyRepository.lastTimeZone, 'America/New_York');
      expect(dailyRepository.lastLangCode, 'en-US');
      expect(foodRepository.lastLangCode, 'en-US');
    },
  );

  test('新增成功後不會因紀錄頁日期重新載入失敗而誤報失敗', () async {
    final repository = _FailingReadDailyRecordRepository();
    final container = ProviderContainer(
      overrides: [dailyRecordRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container
        .read(selectedDateProvider.notifier)
        .select(DateTime(2025, 12, 15));

    await container
        .read(dailyRecordsProvider.notifier)
        .addRecord(
          food: mockFoods[1],
          quantityGrams: 100,
          mealType: MealType.lunch,
          recordDate: DateTime(2026, 7, 28),
        );

    expect(container.read(dailyRecordsProvider).hasError, isFalse);
  });

  test('SelectedDateController 以前後七天切換週期', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(selectedDateProvider.notifier);

    controller.select(DateTime(2026, 7, 29, 18));
    controller.previousWeek();
    expect(container.read(selectedDateProvider), DateTime(2026, 7, 22));

    controller.nextWeek();
    expect(container.read(selectedDateProvider), DateTime(2026, 7, 29));
  });
}

class _FailingReadDailyRecordRepository extends MockDailyRecordRepository {
  _FailingReadDailyRecordRepository() : super(initialRecords: []);

  @override
  Future<List<DailyRecord>> getRecordsForDate(
    DateTime date, {
    required String timeZone,
    required String langCode,
  }) async {
    throw Exception('selected date reload failed');
  }
}

class _RecordingDailyRecordRepository extends MockDailyRecordRepository {
  _RecordingDailyRecordRepository() : super(initialRecords: []);

  String? lastTimeZone;
  String? lastLangCode;

  @override
  Future<List<DailyRecord>> getRecordsForDate(
    DateTime date, {
    required String timeZone,
    required String langCode,
  }) async {
    lastTimeZone = timeZone;
    lastLangCode = langCode;
    return super.getRecordsForDate(
      date,
      timeZone: timeZone,
      langCode: langCode,
    );
  }
}

class _RecordingFoodRepository implements FoodRepository {
  String? lastLangCode;

  @override
  Future<List<Food>> searchFoods({
    required String query,
    required String langCode,
  }) async {
    lastLangCode = langCode;
    return const [];
  }
}
