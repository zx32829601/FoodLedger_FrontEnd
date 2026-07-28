import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../domain/models/food.dart';
import '../domain/models/nutrition_summary.dart';
import '../domain/repositories/food_repository.dart';

/// 透過正式食物搜尋 API 取得可記錄食物。
class ApiFoodRepository implements FoodRepository {
  ApiFoodRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Food>> searchFoods({
    required String query,
    required String langCode,
  }) async {
    final normalizedQuery = query.trim();

    try {
      const pageSize = 100;
      var page = 1;
      var totalCount = 0;
      final foods = <Food>[];
      do {
        final response = await _dio.get<Map<String, Object?>>(
          '/api/foods',
          queryParameters: {
            'query': normalizedQuery,
            'langCode': langCode,
            'page': page,
            'pageSize': pageSize,
          },
        );
        final data = response.data;
        final items = data?['items'];
        if (items is! List) return const [];
        if (items.isEmpty) break;
        foods.addAll(items.map(_mapFood));
        totalCount = (data?['totalCount'] as num?)?.toInt() ?? foods.length;
        page++;
      } while (foods.length < totalCount);
      return List.unmodifiable(foods);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static Food _mapFood(Object? value) {
    final json = Map<String, Object?>.from(value! as Map);
    final rawNutrients = json['nutrients'] is List
        ? json['nutrients']! as List
        : const [];
    final langCode = json['langCode'] as String?;

    return Food(
      id: (json['foodId'] as num).toInt(),
      code: json['foodCode']! as String,
      name: json['displayName']! as String,
      description: '',
      langCode: langCode,
      nutrientsPer100Grams: [
        for (final item in rawNutrients)
          _mapNutrient(
            Map<String, Object?>.from(item! as Map),
            fallbackLangCode: langCode,
          ),
      ],
    );
  }

  static NutrientAmount _mapNutrient(
    Map<String, Object?> json, {
    required String? fallbackLangCode,
  }) {
    return NutrientAmount(
      nutrientId: (json['nutrientId'] as num?)?.toInt() ?? 0,
      code: json['code']! as String,
      displayName: json['displayName']! as String,
      langCode: json['langCode'] as String? ?? fallbackLangCode,
      amount: (json['amountPer100Grams'] as num).toDouble(),
      unitCode: json['unitCode']! as String,
    );
  }
}
