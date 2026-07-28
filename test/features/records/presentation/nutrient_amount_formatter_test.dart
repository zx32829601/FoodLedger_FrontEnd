import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/domain/models/nutrient_codes.dart';
import 'package:food_ledger_frontend/features/records/domain/models/nutrition_summary.dart';
import 'package:food_ledger_frontend/features/records/presentation/nutrient_amount_formatter.dart';
import 'package:food_ledger_frontend/features/records/presentation/nutrient_labels.dart';

void main() {
  test('formatNutrientAmount 依單位保留可讀精度且不把 missing 當零', () {
    expect(formatNutrientAmount(null), '—');
    expect(
      formatNutrientAmount(
        const NutrientAmount(
          nutrientId: 1,
          code: 'Calories',
          displayName: '熱量',
          amount: 120,
          unitCode: 'kcal',
        ),
      ),
      '120 kcal',
    );
    expect(
      formatNutrientAmount(
        const NutrientAmount(
          nutrientId: 2,
          code: 'Protein',
          displayName: '蛋白質',
          amount: 12.36,
          unitCode: 'g',
        ),
      ),
      '12.4 g',
    );
    expect(
      formatNutrientAmount(
        const NutrientAmount(
          nutrientId: 5,
          code: 'Iron',
          displayName: '鐵',
          amount: 0.04,
          unitCode: 'mg',
        ),
      ),
      '0.04 mg',
    );
  });

  test('核心營養素備援標籤由單一對照表提供', () {
    expect(fallbackNutrientLabel(NutrientCodes.calories), '熱量');
    expect(fallbackNutrientLabel(NutrientCodes.protein), '蛋白質');
    expect(shortNutrientLabel(NutrientCodes.fat), '脂');
    expect(fallbackNutrientLabel('Iron'), 'Iron');
  });
}
