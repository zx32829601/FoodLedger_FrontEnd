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
    this.englishName,
    this.categories = const [],
  }) : nutrientsPer100Grams = List.unmodifiable(nutrientsPer100Grams);

  final int id;
  final String code;
  final String name;
  final String description;
  final String? langCode;
  final String? englishName;
  final List<FoodCategory> categories;
  final List<NutrientAmount> nutrientsPer100Grams;

  NutrientAmount? nutrientPer100Grams(String code) {
    return nutrientsPer100Grams.nutrientByCode(code);
  }
}

class FoodCategory {
  const FoodCategory({
    required this.id,
    required this.code,
    required this.displayName,
    required this.langCode,
  });
  final int id;
  final String code;
  final String displayName;
  final String langCode;
}

class FoodSearchItem {
  const FoodSearchItem({
    required this.id,
    required this.code,
    required this.name,
    required this.langCode,
    this.englishName,
    this.caloriesPer100Grams,
  });
  final int id;
  final String code;
  final String name;
  final String langCode;
  final String? englishName;
  final double? caloriesPer100Grams;
}

class FoodSearchResult {
  FoodSearchResult({
    required List<FoodSearchItem> items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  }) : items = List.unmodifiable(items);
  final List<FoodSearchItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();
}
