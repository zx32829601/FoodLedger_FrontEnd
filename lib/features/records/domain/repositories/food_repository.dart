import '../models/food.dart';

/// 食物搜尋資料來源的抽象介面。
abstract interface class FoodRepository {
  Future<List<Food>> searchFoods({
    required String query,
    required String langCode,
  });
}
