import '../models/daily_record.dart';
import '../models/food.dart';

/// 使用者飲食紀錄資料來源的抽象介面。
abstract interface class DailyRecordRepository {
  Future<List<DailyRecord>> getRecordsForDate(
    DateTime date, {
    required String timeZone,
    required String langCode,
  });

  Future<DailyRecord> addRecord({
    required Food food,
    required double quantityGrams,
    required DateTime consumedAt,
    String mealTypeCode = 'Snack',
    String? note,
  });

  Future<void> deleteRecord(int recordId);

  Future<void> updateRecord({
    required int recordId,
    required Food food,
    required double quantityGrams,
    required DateTime consumedAt,
    required String mealTypeCode,
    String? note,
  });
}
