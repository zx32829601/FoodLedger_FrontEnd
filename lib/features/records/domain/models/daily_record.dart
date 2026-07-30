import 'food.dart';
import 'nutrition_summary.dart';

/// 一筆使用者飲食紀錄，餐別使用後端 DefinedCode 的穩定代碼。
class DailyRecord {
  DailyRecord({
    required this.id,
    required this.food,
    required this.quantityGrams,
    required this.consumedAt,
    required this.mealTypeCode,
    required List<NutrientAmount> nutrients,
    this.note,
  }) : nutrients = List.unmodifiable(nutrients);

  final int id;
  final Food food;
  final double quantityGrams;
  final DateTime consumedAt;
  final String mealTypeCode;
  final String? note;
  final List<NutrientAmount> nutrients;

  NutrientAmount? nutrient(String code) => nutrients.nutrientByCode(code);
}
