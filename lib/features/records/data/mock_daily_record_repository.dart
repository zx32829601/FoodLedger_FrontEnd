import '../domain/models/daily_record.dart';
import '../domain/models/food.dart';
import '../domain/models/nutrition_summary.dart';
import '../domain/repositories/daily_record_repository.dart';
import 'mock_foods.dart';

class MockDailyRecordRepository implements DailyRecordRepository {
  MockDailyRecordRepository({List<DailyRecord>? initialRecords})
    : _records = initialRecords == null
          ? _createInitialRecords()
          : List.of(initialRecords),
      _nextId = initialRecords == null
          ? 100
          : initialRecords.fold(0, (maxId, record) {
                  return record.id > maxId ? record.id : maxId;
                }) +
                1;

  final List<DailyRecord> _records;
  int _nextId;

  @override
  Future<List<DailyRecord>> getRecordsForDate(
    DateTime date, {
    required String timeZone,
    required String langCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final records =
        _records.where((record) {
          return _isSameLocalDate(record.consumedAt, date);
        }).toList()..sort((left, right) {
          return left.consumedAt.compareTo(right.consumedAt);
        });

    return List.unmodifiable(records);
  }

  @override
  Future<DailyRecord> addRecord({
    required Food food,
    required double quantityGrams,
    required DateTime consumedAt,
    required String mealTypeCode,
    String? note,
  }) async {
    if (quantityGrams <= 0) {
      throw ArgumentError.value(quantityGrams, 'quantityGrams', '份量必須大於 0');
    }

    await Future<void>.delayed(const Duration(milliseconds: 260));
    final record = DailyRecord(
      id: _nextId++,
      food: food,
      quantityGrams: quantityGrams,
      consumedAt: consumedAt.toUtc(),
      nutrients: food.nutrientsPer100Grams.scaledBy(quantityGrams / 100),
      mealTypeCode: mealTypeCode,
      note: note,
    );
    _records.add(record);
    return record;
  }

  @override
  Future<void> deleteRecord(int recordId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _records.removeWhere((record) => record.id == recordId);
  }

  @override
  Future<void> updateRecord({
    required int recordId,
    required Food food,
    required double quantityGrams,
    required DateTime consumedAt,
    required String mealTypeCode,
    String? note,
  }) async {
    final index = _records.indexWhere((record) => record.id == recordId);
    if (index < 0) return;
    _records[index] = DailyRecord(
      id: recordId,
      food: food,
      quantityGrams: quantityGrams,
      consumedAt: consumedAt.toUtc(),
      nutrients: food.nutrientsPer100Grams.scaledBy(quantityGrams / 100),
      mealTypeCode: mealTypeCode,
      note: note,
    );
  }

  static bool _isSameLocalDate(DateTime left, DateTime right) {
    final localLeft = left.toLocal();
    final localRight = right.toLocal();
    return localLeft.year == localRight.year &&
        localLeft.month == localRight.month &&
        localLeft.day == localRight.day;
  }

  static List<DailyRecord> _createInitialRecords() {
    final now = DateTime.now();
    DateTime consumedAt(int hour, int minute) {
      return DateTime(now.year, now.month, now.day, hour, minute).toUtc();
    }

    return [
      DailyRecord(
        id: 1,
        food: mockFoods[3],
        quantityGrams: 180,
        consumedAt: consumedAt(8, 10),
        mealTypeCode: 'Breakfast',
        nutrients: mockFoods[3].nutrientsPer100Grams.scaledBy(1.8),
      ),
      DailyRecord(
        id: 2,
        food: mockFoods[1],
        quantityGrams: 150,
        consumedAt: consumedAt(12, 20),
        mealTypeCode: 'Lunch',
        nutrients: mockFoods[1].nutrientsPer100Grams.scaledBy(1.5),
      ),
      DailyRecord(
        id: 3,
        food: mockFoods[0],
        quantityGrams: 200,
        consumedAt: consumedAt(12, 20),
        mealTypeCode: 'Lunch',
        nutrients: mockFoods[0].nutrientsPer100Grams.scaledBy(2),
      ),
      DailyRecord(
        id: 4,
        food: mockFoods[4],
        quantityGrams: 120,
        consumedAt: consumedAt(18, 30),
        mealTypeCode: 'Dinner',
        nutrients: mockFoods[4].nutrientsPer100Grams.scaledBy(1.2),
      ),
    ];
  }
}
