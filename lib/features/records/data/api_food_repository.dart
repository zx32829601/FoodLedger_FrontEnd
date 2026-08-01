import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../domain/models/food.dart';
import '../domain/models/nutrition_summary.dart';
import '../domain/repositories/food_repository.dart';

class ApiFoodRepository implements FoodRepository {
  ApiFoodRepository(this._dio);
  final Dio _dio;

  @override
  Future<FoodSearchResult> searchFoods({
    required String query,
    required String langCode,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/api/foods',
        queryParameters: {
          'query': query.trim(),
          'langCode': langCode,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final json = response.data ?? const {};
      final rawItems = json['items'] is List
          ? json['items']! as List
          : const [];
      return FoodSearchResult(
        items: rawItems.map((item) {
          final value = Map<String, Object?>.from(item! as Map);
          return FoodSearchItem(
            id: (value['foodId'] as num).toInt(),
            code: value['foodCode']! as String,
            name: value['displayName']! as String,
            langCode: value['langCode']! as String,
            englishName: value['englishName'] as String?,
            caloriesPer100Grams: (value['caloriesPer100Grams'] as num?)
                ?.toDouble(),
          );
        }).toList(),
        page: (json['page'] as num?)?.toInt() ?? page,
        pageSize: (json['pageSize'] as num?)?.toInt() ?? pageSize,
        totalCount: (json['totalCount'] as num?)?.toInt() ?? rawItems.length,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<Food> getFoodDetail({
    required int foodId,
    required String langCode,
  }) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/api/foods/$foodId',
        queryParameters: {'langCode': langCode},
      );
      final json = response.data!;
      final rawCategories = json['categories'] is List
          ? json['categories']! as List
          : const [];
      final rawNutrients = json['nutrients'] is List
          ? json['nutrients']! as List
          : const [];
      return Food(
        id: (json['foodId'] as num).toInt(),
        code: json['foodCode']! as String,
        name: json['displayName']! as String,
        description: json['description'] as String? ?? '',
        langCode: json['langCode'] as String?,
        englishName: json['englishName'] as String?,
        categories: rawCategories.map((item) {
          final value = Map<String, Object?>.from(item! as Map);
          return FoodCategory(
            id: (value['categoryId'] as num).toInt(),
            code: value['code']! as String,
            displayName: value['displayName']! as String,
            langCode: value['langCode']! as String,
          );
        }).toList(),
        nutrientsPer100Grams: rawNutrients.map((item) {
          final value = Map<String, Object?>.from(item! as Map);
          return NutrientAmount(
            nutrientId: (value['nutrientId'] as num?)?.toInt() ?? 0,
            code: value['code']! as String,
            displayName: value['displayName']! as String,
            langCode: value['langCode'] as String?,
            amount: (value['amountPer100Grams'] as num).toDouble(),
            unitCode: value['unitCode']! as String,
            displayOrder: (value['displayOrder'] as num?)?.toInt() ?? 1000,
          );
        }).toList(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
