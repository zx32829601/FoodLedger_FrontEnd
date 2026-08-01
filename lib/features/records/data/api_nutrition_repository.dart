import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../domain/models/nutrition_summary.dart';
import '../domain/models/weekly_nutrition_summary.dart';
import '../domain/repositories/nutrition_repository.dart';

class ApiNutritionRepository implements NutritionRepository {
  ApiNutritionRepository(this._dio);

  final Dio _dio;

  @override
  Future<NutritionSummary> getDailySummary({
    required DateTime date,
    required String timeZone,
    required String langCode,
  }) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/api/nutrition-summary/daily',
        queryParameters: {
          'date': _dateValue(date),
          'timeZone': timeZone,
          'langCode': langCode,
        },
      );
      final json = response.data ?? const <String, Object?>{};
      return NutritionSummary.fromNutrients(
        date: DateTime.parse(json['date']! as String),
        timeZone: json['timeZone']! as String,
        nutrients: _mapTotals(json['totals']),
        mealTypes: _mapMealTypes(json['mealTypes']),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<WeeklyNutritionSummary> getWeeklySummary({
    required DateTime date,
    required String timeZone,
    required String langCode,
  }) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/api/nutrition-summary/weekly',
        queryParameters: {
          'date': _dateValue(date),
          'timeZone': timeZone,
          'langCode': langCode,
        },
      );
      final json = response.data ?? const <String, Object?>{};
      final rawDays = json['days'] is List ? json['days']! as List : const [];
      return WeeklyNutritionSummary(
        startDate: DateTime.parse(json['startDate']! as String),
        endDate: DateTime.parse(json['endDate']! as String),
        timeZone: json['timeZone']! as String,
        totals: _mapTotals(json['totals']),
        days: [
          for (final item in rawDays)
            DailyNutritionBreakdown(
              date: DateTime.parse(
                Map<String, Object?>.from(item! as Map)['date']! as String,
              ),
              totals: _mapTotals(Map<String, Object?>.from(item)['totals']),
            ),
        ],
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static List<MealTypeNutritionSummary> _mapMealTypes(Object? value) {
    final rawMealTypes = value is List ? value : const [];
    return [
      for (final item in rawMealTypes)
        MealTypeNutritionSummary(
          mealTypeCode:
              Map<String, Object?>.from(item! as Map)['mealTypeCode']!
                  as String,
          totals: _mapTotals(Map<String, Object?>.from(item)['totals']),
        ),
    ];
  }

  static List<NutrientAmount> _mapTotals(Object? value) {
    final rawTotals = value is List ? value : const [];
    return [
      for (final item in rawTotals)
        _mapNutrient(Map<String, Object?>.from(item! as Map)),
    ];
  }

  static NutrientAmount _mapNutrient(Map<String, Object?> json) {
    return NutrientAmount(
      nutrientId: (json['nutrientId'] as num).toInt(),
      code: json['code']! as String,
      displayName: json['displayName']! as String,
      langCode: json['langCode'] as String?,
      amount: (json['amount'] as num).toDouble(),
      unitCode: json['unitCode']! as String,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 1000,
    );
  }

  static String _dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
