import '../domain/models/nutrition_summary.dart';
import '../domain/repositories/daily_record_repository.dart';
import '../domain/repositories/nutrition_repository.dart';

class MockNutritionRepository implements NutritionRepository {
  const MockNutritionRepository(this._dailyRecordRepository);

  final DailyRecordRepository _dailyRecordRepository;

  @override
  Future<NutritionSummary> getSummaryForDate(DateTime date) async {
    final records = await _dailyRecordRepository.getRecordsForDate(date);
    return NutritionSummary.fromRecords(records);
  }
}
