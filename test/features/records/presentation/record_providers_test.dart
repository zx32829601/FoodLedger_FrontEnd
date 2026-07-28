import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/data/mock_daily_record_repository.dart';
import 'package:food_ledger_frontend/features/records/data/mock_foods.dart';
import 'package:food_ledger_frontend/features/records/data/mock_nutrition_repository.dart';
import 'package:food_ledger_frontend/features/records/domain/models/meal_type.dart';
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
    expect(summary.calories, closeTo(165, 0.001));
    expect(summary.protein, closeTo(31, 0.001));
  });
}
