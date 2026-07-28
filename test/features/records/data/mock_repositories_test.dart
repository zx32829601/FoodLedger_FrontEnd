import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/data/mock_daily_record_repository.dart';
import 'package:food_ledger_frontend/features/records/data/mock_food_repository.dart';
import 'package:food_ledger_frontend/features/records/data/mock_foods.dart';
import 'package:food_ledger_frontend/features/records/data/mock_nutrition_repository.dart';

void main() {
  group('MockFoodRepository', () {
    test('searchFoods_WhenQueryMatchesName_ReturnsMatchingFood', () async {
      final repository = MockFoodRepository();

      final foods = await repository.searchFoods(
        query: '雞胸',
        langCode: 'zh-TW',
      );

      expect(foods, hasLength(1));
      expect(foods.single.name, '雞胸肉');
    });
  });

  group('MockDailyRecordRepository', () {
    test('addRecord_WhenQuantityIsValid_AddsRecordForDate', () async {
      final repository = MockDailyRecordRepository(initialRecords: []);
      final consumedAt = DateTime(2026, 7, 21, 12);

      final created = await repository.addRecord(
        food: mockFoods[1],
        quantityGrams: 150,
        consumedAt: consumedAt,
      );
      final records = await repository.getRecordsForDate(
        consumedAt,
        timeZone: 'Asia/Taipei',
        langCode: 'zh-TW',
      );

      expect(records, hasLength(1));
      expect(records.single.id, created.id);
      expect(records.single.quantityGrams, 150);
    });

    test('deleteRecord_WhenRecordExists_RemovesRecord', () async {
      final repository = MockDailyRecordRepository(initialRecords: []);
      final consumedAt = DateTime(2026, 7, 21, 12);
      final created = await repository.addRecord(
        food: mockFoods.first,
        quantityGrams: 100,
        consumedAt: consumedAt,
      );

      await repository.deleteRecord(created.id);
      final records = await repository.getRecordsForDate(
        consumedAt,
        timeZone: 'Asia/Taipei',
        langCode: 'zh-TW',
      );

      expect(records, isEmpty);
    });
  });

  group('MockNutritionRepository', () {
    test('getDailySummary_SumsRecordNutrition', () async {
      final dailyRecordRepository = MockDailyRecordRepository(
        initialRecords: [],
      );
      final nutritionRepository = MockNutritionRepository(
        dailyRecordRepository,
      );
      final consumedAt = DateTime(2026, 7, 21, 12);
      await dailyRecordRepository.addRecord(
        food: mockFoods[1],
        quantityGrams: 200,
        consumedAt: consumedAt,
      );

      final summary = await nutritionRepository.getDailySummary(
        date: consumedAt,
        timeZone: 'Asia/Taipei',
        langCode: 'zh-TW',
      );

      expect(summary.nutrient('Calories')?.amount, closeTo(330, 0.001));
      expect(summary.nutrient('Protein')?.amount, closeTo(62, 0.001));
      expect(summary.nutrient('Fat')?.amount, closeTo(7.2, 0.001));
      expect(summary.nutrient('Carbohydrates')?.amount, closeTo(0, 0.001));
    });
  });
}
