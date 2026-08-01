import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/domain/models/daily_record.dart';
import 'package:food_ledger_frontend/features/records/domain/models/food.dart';
import 'package:food_ledger_frontend/features/records/domain/models/nutrition_summary.dart';
import 'package:food_ledger_frontend/features/records/domain/models/weekly_nutrition_summary.dart';

void main() {
  const protein = NutrientAmount(
    nutrientId: 2,
    code: 'Protein',
    displayName: '蛋白質',
    amount: 20,
    unitCode: 'g',
  );

  test('nutrientByCode 找不到營養素時保留 missing 語意', () {
    expect([protein].nutrientByCode('Protein'), same(protein));
    expect([protein].nutrientByCode('Calories'), isNull);
  });

  test('scaledBy 建立換算後的新清單且不修改來源', () {
    final scaled = [protein].scaledBy(1.5);

    expect(scaled.single.amount, 30);
    expect(protein.amount, 20);
  });

  test('營養摘要建構後不允許外部修改巢狀清單', () {
    final meal = MealTypeNutritionSummary(
      mealTypeCode: 'Lunch',
      totals: [protein],
    );
    final summary = NutritionSummary.fromNutrients(
      date: DateTime(2026, 7, 28),
      timeZone: 'Asia/Taipei',
      nutrients: [protein],
      mealTypes: [meal],
    );
    final weekly = WeeklyNutritionSummary(
      startDate: DateTime(2026, 7, 27),
      endDate: DateTime(2026, 8, 2),
      timeZone: 'Asia/Taipei',
      totals: [protein],
      days: [
        DailyNutritionBreakdown(date: DateTime(2026, 7, 28), totals: [protein]),
      ],
    );
    final food = Food(
      id: 1,
      code: 'CHICKEN',
      name: '雞胸肉',
      description: '',
      nutrientsPer100Grams: [protein],
    );
    final record = DailyRecord(
      id: 1,
      food: food,
      quantityGrams: 100,
      consumedAt: DateTime.utc(2026, 7, 28),
      mealTypeCode: 'Lunch',
      nutrients: [protein],
    );

    expect(() => meal.totals.add(protein), throwsUnsupportedError);
    expect(() => summary.nutrients.clear(), throwsUnsupportedError);
    expect(() => weekly.totals.clear(), throwsUnsupportedError);
    expect(() => weekly.days.single.totals.clear(), throwsUnsupportedError);
    expect(() => food.nutrientsPer100Grams.clear(), throwsUnsupportedError);
    expect(() => record.nutrients.clear(), throwsUnsupportedError);
  });
}
