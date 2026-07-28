import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/antiforgery_request.dart';
import '../domain/admin_food.dart';
import '../domain/admin_food_repository.dart';
import '../domain/nutrient_definition.dart';

/// 封裝管理員食物 CRUD HTTP 契約。
class ApiAdminFoodRepository implements AdminFoodRepository {
  ApiAdminFoodRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<NutrientDefinition>> getNutrients({
    required String langCode,
  }) async {
    try {
      final response = await _dio.get<List<Object?>>(
        '/api/nutrients',
        queryParameters: {'langCode': langCode},
      );
      return [
        for (final item in response.data ?? const [])
          _mapNutrientDefinition(Map<String, Object?>.from(item! as Map)),
      ];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AdminFood> get(int foodId) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/api/admin/foods/$foodId',
      );
      return _map(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AdminFood> save({
    int? foodId,
    required String foodCode,
    required Map<String, AdminFoodTranslation> translations,
    required Map<String, double> nutrients,
  }) async {
    final data = {
      'foodCode': foodCode.trim(),
      'translations': [
        for (final entry in translations.entries)
          {
            'langCode': entry.key,
            'displayName': entry.value.displayName.trim(),
            'description': entry.value.description.trim(),
          },
      ],
      'nutrients': [
        for (final entry in nutrients.entries)
          {'nutrientCode': entry.key, 'amountPer100Grams': entry.value},
      ],
    };
    try {
      final options = await antiforgeryRequestOptions(_dio);
      final response = foodId == null
          ? await _dio.post<Map<String, Object?>>(
              '/api/admin/foods',
              data: data,
              options: options,
            )
          : await _dio.put<Map<String, Object?>>(
              '/api/admin/foods/$foodId',
              data: data,
              options: options,
            );
      return _map(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> delete(int foodId) async {
    try {
      await _dio.delete<void>(
        '/api/admin/foods/$foodId',
        options: await antiforgeryRequestOptions(_dio),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static AdminFood _map(Map<String, Object?> json) {
    final translations = json['translations']! as List;
    final nutrients = json['nutrients']! as List;
    return AdminFood(
      id: (json['foodId'] as num).toInt(),
      code: json['foodCode']! as String,
      translations: Map.fromEntries(translations.map(_mapTranslation)),
      nutrients: Map.fromEntries(nutrients.map(_mapNutrient)),
    );
  }

  static MapEntry<String, double> _mapNutrient(Object? value) {
    final nutrient = Map<String, Object?>.from(value! as Map);
    return MapEntry(
      nutrient['nutrientCode']! as String,
      (nutrient['amountPer100Grams'] as num).toDouble(),
    );
  }

  static NutrientDefinition _mapNutrientDefinition(Map<String, Object?> json) {
    return NutrientDefinition(
      nutrientId: (json['nutrientId'] as num).toInt(),
      code: json['code']! as String,
      displayName: json['displayName']! as String,
      langCode: json['langCode'] as String?,
      unitCode: json['unitCode']! as String,
    );
  }

  static MapEntry<String, AdminFoodTranslation> _mapTranslation(Object? value) {
    final translation = Map<String, Object?>.from(value! as Map);
    return MapEntry(
      translation['langCode']! as String,
      AdminFoodTranslation(
        displayName: translation['displayName']! as String,
        description: translation['description'] as String? ?? '',
      ),
    );
  }
}
