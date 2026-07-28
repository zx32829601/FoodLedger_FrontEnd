class NutrientAmount {
  const NutrientAmount({
    required this.nutrientId,
    required this.code,
    required this.displayName,
    required this.amount,
    required this.unitCode,
    this.langCode,
  });

  final int nutrientId;
  final String code;
  final String displayName;
  final String? langCode;
  final double amount;
  final String unitCode;
}

extension NutrientAmountCollection on Iterable<NutrientAmount> {
  /// 依穩定營養素代碼取得數值；找不到時回傳 `null`。
  NutrientAmount? nutrientByCode(String code) {
    for (final nutrient in this) {
      if (nutrient.code == code) return nutrient;
    }
    return null;
  }

  /// 依份量比例建立新的營養素清單，保留穩定代碼與翻譯資訊。
  List<NutrientAmount> scaledBy(double factor) {
    return [
      for (final nutrient in this)
        NutrientAmount(
          nutrientId: nutrient.nutrientId,
          code: nutrient.code,
          displayName: nutrient.displayName,
          langCode: nutrient.langCode,
          amount: nutrient.amount * factor,
          unitCode: nutrient.unitCode,
        ),
    ];
  }
}

class MealTypeNutritionSummary {
  MealTypeNutritionSummary({
    required this.mealTypeCode,
    required List<NutrientAmount> totals,
  }) : totals = List.unmodifiable(totals);

  final String mealTypeCode;
  final List<NutrientAmount> totals;

  NutrientAmount? nutrient(String code) => totals.nutrientByCode(code);
}

/// 單日營養摘要；API 資料以動態營養素清單為準。
class NutritionSummary {
  NutritionSummary._({
    required this.date,
    required this.timeZone,
    required this.nutrients,
    required this.mealTypes,
  });

  factory NutritionSummary.fromNutrients({
    required DateTime date,
    required String timeZone,
    required List<NutrientAmount> nutrients,
    required List<MealTypeNutritionSummary> mealTypes,
  }) {
    return NutritionSummary._(
      date: date,
      timeZone: timeZone,
      nutrients: List.unmodifiable(nutrients),
      mealTypes: List.unmodifiable(mealTypes),
    );
  }

  final DateTime date;
  final String timeZone;
  final List<NutrientAmount> nutrients;
  final List<MealTypeNutritionSummary> mealTypes;

  NutrientAmount? nutrient(String code) => nutrients.nutrientByCode(code);
}
