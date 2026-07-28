import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/antiforgery_request.dart';
import '../domain/models/daily_record.dart';
import '../domain/models/food.dart';
import '../domain/models/nutrition_summary.dart';
import '../domain/repositories/daily_record_repository.dart';

/// 透過正式 Daily Record API 查詢、新增與刪除使用者紀錄。
class ApiDailyRecordRepository implements DailyRecordRepository {
  ApiDailyRecordRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<DailyRecord>> getRecordsForDate(
    DateTime date, {
    required String timeZone,
    required String langCode,
  }) async {
    try {
      final response = await _dio.get<List<Object?>>(
        '/api/daily-records',
        queryParameters: {
          'date': _dateValue(date),
          'timeZone': timeZone,
          'langCode': langCode,
        },
      );
      return (response.data ?? const [])
          .map(_mapRecord)
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<DailyRecord> addRecord({
    required Food food,
    required double quantityGrams,
    required DateTime consumedAt,
    String mealTypeCode = 'Snack',
    String? note,
  }) async {
    try {
      await _dio.post<void>(
        '/api/daily-records',
        options: await antiforgeryRequestOptions(_dio),
        data: {
          'foodId': food.id,
          'quantity': quantityGrams,
          'consumedAt': consumedAt.toUtc().toIso8601String(),
          'mealTypeCode': mealTypeCode,
          'note': note?.trim().isEmpty == true ? null : note?.trim(),
        },
      );
      return DailyRecord(
        id: 0,
        food: food,
        quantityGrams: quantityGrams,
        consumedAt: consumedAt.toUtc(),
        nutrients: food.nutrientsPer100Grams.scaledBy(quantityGrams / 100),
        mealTypeCode: mealTypeCode,
        note: note,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> deleteRecord(int recordId) async {
    try {
      await _dio.delete<void>(
        '/api/daily-records/$recordId',
        options: await antiforgeryRequestOptions(_dio),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
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
    try {
      await _dio.put<void>(
        '/api/daily-records/$recordId',
        options: await antiforgeryRequestOptions(_dio),
        data: {
          'foodId': food.id,
          'quantity': quantityGrams,
          'consumedAt': consumedAt.toUtc().toIso8601String(),
          'mealTypeCode': mealTypeCode,
          'note': note?.trim().isEmpty == true ? null : note?.trim(),
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static DailyRecord _mapRecord(Object? value) {
    final json = Map<String, Object?>.from(value! as Map);
    final foodId = (json['foodId'] as num).toInt();
    final foodJson = json['food'] is Map
        ? Map<String, Object?>.from(json['food']! as Map)
        : const <String, Object?>{};
    final rawNutrients = json['nutrients'] is List
        ? json['nutrients']! as List
        : const [];
    final quantity = (json['quantity'] as num).toDouble();
    final nutrients = [
      for (final item in rawNutrients)
        _mapNutrient(Map<String, Object?>.from(item! as Map)),
    ];

    return DailyRecord(
      id: (json['recordId'] as num).toInt(),
      food: Food(
        id: foodId,
        code: foodJson['foodCode'] as String? ?? 'FOOD_$foodId',
        name: foodJson['displayName'] as String? ?? '食物 #$foodId',
        description: '',
        langCode: foodJson['langCode'] as String?,
        nutrientsPer100Grams: const [],
      ),
      quantityGrams: quantity,
      consumedAt: DateTime.parse(json['consumedAt']! as String),
      nutrients: nutrients,
      mealTypeCode: json['mealTypeCode']! as String,
      note: json['note'] as String?,
    );
  }

  static NutrientAmount _mapNutrient(Map<String, Object?> json) {
    return NutrientAmount(
      nutrientId: (json['nutrientId'] as num).toInt(),
      code: json['code']! as String,
      displayName: json['displayName']! as String,
      langCode: json['langCode'] as String?,
      amount: (json['amount'] as num).toDouble(),
      unitCode: json['unitCode']! as String,
    );
  }

  static String _dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
