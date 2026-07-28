import 'food.dart';
import 'meal_type.dart';
import 'nutrition_summary.dart';

/// 一筆使用者飲食紀錄，餐別由食用時間推導。
class DailyRecord {
  DailyRecord({
    required this.id,
    required this.food,
    required this.quantityGrams,
    required this.consumedAt,
    required List<NutrientAmount> nutrients,
    this.mealTypeCode,
    this.note,
  }) : nutrients = List.unmodifiable(nutrients);

  final int id;
  final Food food;
  final double quantityGrams;
  final DateTime consumedAt;
  final String? mealTypeCode;
  final String? note;
  final List<NutrientAmount> nutrients;

  MealType get mealType =>
      MealType.fromCode(mealTypeCode) ?? MealType.fromConsumedAt(consumedAt);

  NutrientAmount? nutrient(String code) => nutrients.nutrientByCode(code);
}
