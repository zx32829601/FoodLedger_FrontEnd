import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../domain/models/meal_type_option.dart';
import '../domain/repositories/defined_code_repository.dart';

/// 透過 DefinedCode API 取得目前可供新飲食紀錄使用的餐別。
class ApiDefinedCodeRepository implements DefinedCodeRepository {
  ApiDefinedCodeRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<MealTypeOption>> getMealTypes() async {
    try {
      final response = await _dio.get<List<Object?>>(
        '/api/defined-codes/meal-types',
      );
      final options =
          [
            for (final value in response.data ?? const [])
              _mapOption(Map<String, Object?>.from(value! as Map)),
          ]..sort((left, right) {
            final sortOrderComparison = left.sortOrder.compareTo(
              right.sortOrder,
            );
            return sortOrderComparison != 0
                ? sortOrderComparison
                : left.code.compareTo(right.code);
          });
      return List.unmodifiable(options);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static MealTypeOption _mapOption(Map<String, Object?> json) {
    return MealTypeOption(
      code: json['code']! as String,
      displayName: json['displayName']! as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );
  }
}
