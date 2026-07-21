import 'daily_record.dart';

/// 熱量與三大營養素的彙總數值。
class NutritionSummary {
  const NutritionSummary({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbohydrates,
  });

  const NutritionSummary.zero()
    : calories = 0,
      protein = 0,
      fat = 0,
      carbohydrates = 0;

  final double calories;
  final double protein;
  final double fat;
  final double carbohydrates;

  NutritionSummary operator +(NutritionSummary other) {
    return NutritionSummary(
      calories: calories + other.calories,
      protein: protein + other.protein,
      fat: fat + other.fat,
      carbohydrates: carbohydrates + other.carbohydrates,
    );
  }

  NutritionSummary scaledBy(double factor) {
    return NutritionSummary(
      calories: calories * factor,
      protein: protein * factor,
      fat: fat * factor,
      carbohydrates: carbohydrates * factor,
    );
  }

  static NutritionSummary fromRecords(Iterable<DailyRecord> records) {
    return records.fold(
      const NutritionSummary.zero(),
      (summary, record) => summary + record.nutrition,
    );
  }
}
