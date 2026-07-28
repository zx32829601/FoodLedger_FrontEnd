import 'nutrition_summary.dart';

class DailyNutritionBreakdown {
  DailyNutritionBreakdown({
    required this.date,
    required List<NutrientAmount> totals,
  }) : totals = List.unmodifiable(totals);

  final DateTime date;
  final List<NutrientAmount> totals;

  NutrientAmount? nutrient(String code) => totals.nutrientByCode(code);
}

class WeeklyNutritionSummary {
  WeeklyNutritionSummary({
    required this.startDate,
    required this.endDate,
    required this.timeZone,
    required List<NutrientAmount> totals,
    required List<DailyNutritionBreakdown> days,
  }) : totals = List.unmodifiable(totals),
       days = List.unmodifiable(days);

  final DateTime startDate;
  final DateTime endDate;
  final String timeZone;
  final List<NutrientAmount> totals;
  final List<DailyNutritionBreakdown> days;

  NutrientAmount? nutrient(String code) => totals.nutrientByCode(code);
}
