import '../domain/models/nutrient_codes.dart';

/// 當 API 沒有提供翻譯時，顯示核心營養素的繁體中文備援名稱。
String fallbackNutrientLabel(String code) {
  return switch (code) {
    NutrientCodes.calories => '熱量',
    NutrientCodes.protein => '蛋白質',
    NutrientCodes.fat => '脂肪',
    NutrientCodes.carbohydrates => '碳水化合物',
    _ => code,
  };
}
