import 'nutrition_summary.dart';

/// 可被搜尋並加入飲食紀錄的食物。
class Food {
  const Food({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.nutritionPer100Grams,
  });

  final int id;
  final String code;
  final String name;
  final String description;
  final NutritionSummary nutritionPer100Grams;
}
