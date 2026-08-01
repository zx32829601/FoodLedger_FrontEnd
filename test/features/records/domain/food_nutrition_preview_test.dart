import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/domain/models/food_nutrition_preview.dart';
import 'package:food_ledger_frontend/features/records/domain/models/nutrition_summary.dart';

void main() {
  test('150 克會換算每 100 克營養並依 displayOrder 排序', () {
    const nutrients = [
      NutrientAmount(
        nutrientId: 2,
        code: 'Sodium',
        displayName: '鈉',
        amount: 74,
        unitCode: 'mg',
        displayOrder: 50,
      ),
      NutrientAmount(
        nutrientId: 1,
        code: 'Protein',
        displayName: '蛋白質',
        amount: 31,
        unitCode: 'g',
        displayOrder: 20,
      ),
    ];

    final preview = FoodNutritionPreview.calculate(nutrients, 150);

    expect(preview.map((item) => item.code), ['Protein', 'Sodium']);
    expect(preview.first.amount, 46.5);
    expect(preview.last.amount, 111);
  });

  test('克數只允許 0.1 至 10000 且最多一位小數', () {
    expect(FoodNutritionPreview.parseQuantity('0.1'), 0.1);
    expect(FoodNutritionPreview.parseQuantity('10000'), 10000);
    expect(FoodNutritionPreview.parseQuantity('1.25'), isNull);
    expect(FoodNutritionPreview.parseQuantity('10000.1'), isNull);
  });
}
