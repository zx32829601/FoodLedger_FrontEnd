import 'nutrition_summary.dart';

/// 可被搜尋並加入飲食紀錄的食物。
class Food {
  Food({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required List<NutrientAmount> nutrientsPer100Grams,
    this.langCode,
  }) : nutrientsPer100Grams = List.unmodifiable(nutrientsPer100Grams);

  final int id;
  final String code;
  final String name;
  final String description;
  final String? langCode;
  final List<NutrientAmount> nutrientsPer100Grams;

  NutrientAmount? nutrientPer100Grams(String code) {
    return nutrientsPer100Grams.nutrientByCode(code);
  }
}
