import 'food.dart';
import 'meal_type.dart';
import 'nutrition_summary.dart';

/// 一筆使用者飲食紀錄，餐別由食用時間推導。
class DailyRecord {
  const DailyRecord({
    required this.id,
    required this.food,
    required this.quantityGrams,
    required this.consumedAt,
    this.mealTypeCode,
    this.note,
  });

  final int id;
  final Food food;
  final double quantityGrams;
  final DateTime consumedAt;
  final String? mealTypeCode;
  final String? note;

  MealType get mealType =>
      MealType.fromCode(mealTypeCode) ?? MealType.fromConsumedAt(consumedAt);

  NutritionSummary get nutrition {
    return food.nutritionPer100Grams.scaledBy(quantityGrams / 100);
  }
}
