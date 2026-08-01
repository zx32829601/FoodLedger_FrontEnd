import '../domain/models/nutrition_summary.dart';
import '../domain/models/weekly_nutrition_summary.dart';
import '../domain/repositories/daily_record_repository.dart';
import '../domain/repositories/nutrition_repository.dart';

class MockNutritionRepository implements NutritionRepository {
  const MockNutritionRepository(this._dailyRecordRepository);

  static const _daysPerWeek = 7;

  final DailyRecordRepository _dailyRecordRepository;

  @override
  Future<NutritionSummary> getDailySummary({
    required DateTime date,
    required String timeZone,
    required String langCode,
  }) async {
    final records = await _dailyRecordRepository.getRecordsForDate(
      date,
      timeZone: timeZone,
      langCode: langCode,
    );
    return NutritionSummary.fromNutrients(
      date: date,
      timeZone: timeZone,
      nutrients: _aggregate(records.expand((record) => record.nutrients)),
      mealTypes: const [],
    );
  }

  @override
  Future<WeeklyNutritionSummary> getWeeklySummary({
    required DateTime date,
    required String timeZone,
    required String langCode,
  }) async {
    final startDate = date.subtract(Duration(days: date.weekday - 1));
    final days = <DailyNutritionBreakdown>[];

    for (var index = 0; index < _daysPerWeek; index++) {
      final day = DateTime(
        startDate.year,
        startDate.month,
        startDate.day + index,
      );
      final summary = await getDailySummary(
        date: day,
        timeZone: timeZone,
        langCode: langCode,
      );
      days.add(DailyNutritionBreakdown(date: day, totals: summary.nutrients));
    }

    return WeeklyNutritionSummary(
      startDate: startDate,
      endDate: startDate.add(const Duration(days: _daysPerWeek - 1)),
      timeZone: timeZone,
      totals: _aggregate(days.expand((day) => day.totals)),
      days: days,
    );
  }

  static List<NutrientAmount> _aggregate(Iterable<NutrientAmount> nutrients) {
    final totals = <String, NutrientAmount>{};
    for (final nutrient in nutrients) {
      final existing = totals[nutrient.code];
      totals[nutrient.code] = NutrientAmount(
        nutrientId: nutrient.nutrientId,
        code: nutrient.code,
        displayName: nutrient.displayName,
        langCode: nutrient.langCode,
        amount: (existing?.amount ?? 0) + nutrient.amount,
        unitCode: nutrient.unitCode,
        displayOrder: nutrient.displayOrder,
      );
    }
    final sortedTotals = totals.values.toList()
      ..sort((left, right) {
        final order = left.displayOrder.compareTo(right.displayOrder);
        return order == 0 ? left.code.compareTo(right.code) : order;
      });
    return sortedTotals;
  }
}
