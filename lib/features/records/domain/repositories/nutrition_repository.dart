import '../models/nutrition_summary.dart';

/// 每日營養彙總資料來源的抽象介面。
abstract interface class NutritionRepository {
  Future<NutritionSummary> getSummaryForDate(DateTime date);
}
