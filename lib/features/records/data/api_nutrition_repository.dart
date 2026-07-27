import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../domain/models/nutrition_summary.dart';
import '../domain/repositories/nutrition_repository.dart';

/// 透過後端每日營養摘要 API 取得統一計算結果。
class ApiNutritionRepository implements NutritionRepository {
  ApiNutritionRepository(this._dio);

  final Dio _dio;

  @override
  Future<NutritionSummary> getSummaryForDate(DateTime date) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/api/nutrition-summary/daily',
        queryParameters: {'date': _dateValue(date)},
      );
      final totals = response.data?['totals'] is List
          ? response.data!['totals']! as List
          : const [];
      double amount(String code) {
        for (final item in totals) {
          final total = Map<String, Object?>.from(item! as Map);
          if (total['code'] == code) {
            return (total['amount'] as num).toDouble();
          }
        }
        return 0;
      }

      return NutritionSummary(
        calories: amount('Calories'),
        protein: amount('Protein'),
        fat: amount('Fat'),
        carbohydrates: amount('Carbohydrates'),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static String _dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
