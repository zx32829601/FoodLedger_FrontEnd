import '../domain/models/food.dart';
import '../domain/models/nutrition_summary.dart';

const mockFoods = [
  Food(
    id: 1,
    code: 'RICE_WHITE',
    name: '白飯',
    description: '熟白米飯，每 100 克營養資料。',
    nutritionPer100Grams: NutritionSummary(
      calories: 130,
      protein: 2.4,
      fat: 0.3,
      carbohydrates: 28.2,
    ),
  ),
  Food(
    id: 2,
    code: 'CHICKEN_BREAST',
    name: '雞胸肉',
    description: '熟雞胸肉，每 100 克營養資料。',
    nutritionPer100Grams: NutritionSummary(
      calories: 165,
      protein: 31,
      fat: 3.6,
      carbohydrates: 0,
    ),
  ),
  Food(
    id: 3,
    code: 'BOILED_EGG',
    name: '水煮蛋',
    description: '水煮全蛋，每 100 克營養資料。',
    nutritionPer100Grams: NutritionSummary(
      calories: 155,
      protein: 13,
      fat: 11,
      carbohydrates: 1.1,
    ),
  ),
  Food(
    id: 4,
    code: 'SWEET_POTATO',
    name: '地瓜',
    description: '蒸熟地瓜，每 100 克營養資料。',
    nutritionPer100Grams: NutritionSummary(
      calories: 90,
      protein: 2,
      fat: 0.2,
      carbohydrates: 20.7,
    ),
  ),
  Food(
    id: 5,
    code: 'BROCCOLI',
    name: '花椰菜',
    description: '熟綠花椰菜，每 100 克營養資料。',
    nutritionPer100Grams: NutritionSummary(
      calories: 35,
      protein: 2.4,
      fat: 0.4,
      carbohydrates: 7.2,
    ),
  ),
  Food(
    id: 6,
    code: 'BANANA',
    name: '香蕉',
    description: '新鮮香蕉，每 100 克營養資料。',
    nutritionPer100Grams: NutritionSummary(
      calories: 89,
      protein: 1.1,
      fat: 0.3,
      carbohydrates: 22.8,
    ),
  ),
  Food(
    id: 7,
    code: 'PLAIN_YOGURT',
    name: '無糖優格',
    description: '原味無糖優格，每 100 克營養資料。',
    nutritionPer100Grams: NutritionSummary(
      calories: 61,
      protein: 3.5,
      fat: 3.3,
      carbohydrates: 4.7,
    ),
  ),
];
