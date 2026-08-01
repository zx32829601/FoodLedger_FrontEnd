import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/localization/localization_providers.dart';
import 'package:food_ledger_frontend/features/records/data/mock_daily_record_repository.dart';
import 'package:food_ledger_frontend/features/records/data/mock_foods.dart';
import 'package:food_ledger_frontend/features/records/data/mock_nutrition_repository.dart';
import 'package:food_ledger_frontend/features/records/domain/models/daily_record.dart';
import 'package:food_ledger_frontend/features/records/domain/models/food.dart';
import 'package:food_ledger_frontend/features/records/domain/models/meal_type_option.dart';
import 'package:food_ledger_frontend/features/records/domain/repositories/defined_code_repository.dart';
import 'package:food_ledger_frontend/features/records/domain/repositories/food_repository.dart';
import 'package:food_ledger_frontend/features/records/presentation/providers/record_providers.dart';

void main() {
  test('MealTypeOptionsProvider 使用後端 DefinedCode 選項', () async {
    final container = ProviderContainer(
      overrides: [
        definedCodeRepositoryProvider.overrideWithValue(
          _FakeDefinedCodeRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final options = await container.read(mealTypeOptionsProvider.future);

    expect(options.map((option) => option.code), ['Brunch', 'Dinner']);
    expect(options.first.displayName, '早午餐');
  });

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
          mealTypeCode: 'Lunch',
          note: '公司午餐',
        );
    final records = await container.read(dailyRecordsProvider.future);
    final summary = await container.read(nutritionSummaryProvider.future);

    expect(records, hasLength(1));
    expect(records.single.mealTypeCode, 'Lunch');
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

  test('新增成功後重新載入失敗不會讓新增操作失敗且保留錯誤狀態', () async {
    final repository = _FailingReadDailyRecordRepository();
    final container = ProviderContainer(
      overrides: [dailyRecordRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container
        .read(selectedDateProvider.notifier)
        .select(DateTime(2025, 12, 15));

    await expectLater(
      container
          .read(dailyRecordsProvider.notifier)
          .addRecord(
            food: mockFoods[1],
            quantityGrams: 100,
            mealTypeCode: 'Lunch',
            recordDate: DateTime(2026, 7, 28),
          ),
      completes,
    );

    expect(container.read(dailyRecordsProvider).hasError, isTrue);
  });

  test('指定紀錄日期時會用 Nutrition IANA 時區建立飲食時間', () async {
    final repository = _RecordingConsumedAtRepository();
    final container = ProviderContainer(
      overrides: [dailyRecordRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container
        .read(nutritionTimeZoneProvider.notifier)
        .select('America/New_York');

    await container
        .read(dailyRecordsProvider.notifier)
        .addRecord(
          food: mockFoods[1],
          quantityGrams: 100,
          mealTypeCode: 'Lunch',
          recordDate: DateTime(2026, 7, 28),
        );

    expect(repository.lastConsumedAt?.toUtc(), DateTime.utc(2026, 7, 28, 16));
  });

  test('新增 API 失敗會回傳操作錯誤', () async {
    final container = ProviderContainer(
      overrides: [
        dailyRecordRepositoryProvider.overrideWithValue(
          _FailingAddDailyRecordRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(dailyRecordsProvider.notifier)
          .addRecord(
            food: mockFoods[1],
            quantityGrams: 100,
            mealTypeCode: 'Lunch',
          ),
      throwsA(isA<Exception>()),
    );
    expect(container.read(dailyRecordsProvider).hasError, isTrue);
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

class _FakeDefinedCodeRepository implements DefinedCodeRepository {
  @override
  Future<List<MealTypeOption>> getMealTypes() async {
    return const [
      MealTypeOption(code: 'Brunch', displayName: '早午餐', sortOrder: 1),
      MealTypeOption(code: 'Dinner', displayName: '晚餐', sortOrder: 2),
    ];
  }
}

class _FailingAddDailyRecordRepository extends MockDailyRecordRepository {
  _FailingAddDailyRecordRepository() : super(initialRecords: []);

  @override
  Future<DailyRecord> addRecord({
    required Food food,
    required double quantityGrams,
    required DateTime consumedAt,
    String mealTypeCode = 'Snack',
    String? note,
  }) async {
    throw Exception('add failed');
  }
}

class _RecordingConsumedAtRepository extends MockDailyRecordRepository {
  _RecordingConsumedAtRepository() : super(initialRecords: []);

  DateTime? lastConsumedAt;

  @override
  Future<DailyRecord> addRecord({
    required Food food,
    required double quantityGrams,
    required DateTime consumedAt,
    String mealTypeCode = 'Snack',
    String? note,
  }) {
    lastConsumedAt = consumedAt;
    return super.addRecord(
      food: food,
      quantityGrams: quantityGrams,
      consumedAt: consumedAt,
      mealTypeCode: mealTypeCode,
      note: note,
    );
  }
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
