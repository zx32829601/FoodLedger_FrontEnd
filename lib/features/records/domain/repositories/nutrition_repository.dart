import '../models/nutrition_summary.dart';
import '../models/weekly_nutrition_summary.dart';

/// 每日營養彙總資料來源的抽象介面。
abstract interface class NutritionRepository {
  Future<NutritionSummary> getDailySummary({
    required DateTime date,
    required String timeZone,
    required String langCode,
  });

  Future<WeeklyNutritionSummary> getWeeklySummary({
    required DateTime date,
    required String timeZone,
    required String langCode,
  });
}
