import 'admin_food.dart';
import 'nutrient_definition.dart';

/// 隔離管理員食物頁與 HTTP 實作的資料來源介面。
abstract interface class AdminFoodRepository {
  Future<AdminFood> get(int foodId);

  Future<List<NutrientDefinition>> getNutrients({required String langCode});

  Future<AdminFood> save({
    int? foodId,
    required String foodCode,
    required Map<String, AdminFoodTranslation> translations,
    required Map<String, double> nutrients,
  });

  Future<void> delete(int foodId);
}
