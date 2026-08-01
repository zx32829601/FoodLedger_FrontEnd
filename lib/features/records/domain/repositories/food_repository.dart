import '../models/food.dart';

/// 食物搜尋資料來源的抽象介面。
abstract interface class FoodRepository {
  Future<FoodSearchResult> searchFoods({
    required String query,
    required String langCode,
    required int page,
    required int pageSize,
  });

  Future<Food> getFoodDetail({required int foodId, required String langCode});
}
