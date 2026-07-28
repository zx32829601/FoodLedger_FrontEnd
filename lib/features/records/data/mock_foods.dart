import '../domain/models/food.dart';
import '../domain/models/nutrient_codes.dart';
import '../domain/models/nutrient_unit_codes.dart';
import '../domain/models/nutrition_summary.dart';

final mockFoods = [
  _food(1, 'RICE_WHITE', '白飯', '熟白米飯，每 100 克營養資料。', 130, 2.4, 0.3, 28.2),
  _food(2, 'CHICKEN_BREAST', '雞胸肉', '熟雞胸肉，每 100 克營養資料。', 165, 31, 3.6, 0),
  _food(3, 'BOILED_EGG', '水煮蛋', '水煮全蛋，每 100 克營養資料。', 155, 13, 11, 1.1),
  _food(4, 'SWEET_POTATO', '地瓜', '蒸熟地瓜，每 100 克營養資料。', 90, 2, 0.2, 20.7),
  _food(5, 'BROCCOLI', '花椰菜', '熟綠花椰菜，每 100 克營養資料。', 35, 2.4, 0.4, 7.2),
  _food(6, 'BANANA', '香蕉', '新鮮香蕉，每 100 克營養資料。', 89, 1.1, 0.3, 22.8),
  _food(7, 'PLAIN_YOGURT', '無糖優格', '原味無糖優格，每 100 克營養資料。', 61, 3.5, 3.3, 4.7),
];

Food _food(
  int id,
  String code,
  String name,
  String description,
  double calories,
  double protein,
  double fat,
  double carbohydrates,
) {
  return Food(
    id: id,
    code: code,
    name: name,
    description: description,
    langCode: 'zh-TW',
    nutrientsPer100Grams: [
      NutrientAmount(
        nutrientId: 1,
        code: NutrientCodes.calories,
        displayName: '熱量',
        langCode: 'zh-TW',
        amount: calories,
        unitCode: NutrientUnitCodes.kilocalorie,
      ),
      NutrientAmount(
        nutrientId: 2,
        code: NutrientCodes.protein,
        displayName: '蛋白質',
        langCode: 'zh-TW',
        amount: protein,
        unitCode: NutrientUnitCodes.gram,
      ),
      NutrientAmount(
        nutrientId: 3,
        code: NutrientCodes.fat,
        displayName: '脂肪',
        langCode: 'zh-TW',
        amount: fat,
        unitCode: NutrientUnitCodes.gram,
      ),
      NutrientAmount(
        nutrientId: 4,
        code: NutrientCodes.carbohydrates,
        displayName: '碳水化合物',
        langCode: 'zh-TW',
        amount: carbohydrates,
        unitCode: NutrientUnitCodes.gram,
      ),
    ],
  );
}
