import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/data/api_daily_record_repository.dart';
import 'package:food_ledger_frontend/features/records/data/api_food_repository.dart';
import 'package:food_ledger_frontend/features/records/domain/models/food.dart';
import 'package:food_ledger_frontend/features/records/domain/models/nutrition_summary.dart';

void main() {
  group('ApiFoodRepository', () {
    test('搜尋結果會轉換動態營養素', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return {
          'items': [
            {
              'foodId': 1,
              'foodCode': 'CHICKEN',
              'displayName': '雞胸肉',
              'nutrients': [
                {
                  'code': 'Protein',
                  'displayName': '蛋白質',
                  'amountPer100Grams': 31,
                  'unitCode': 'g',
                },
              ],
            },
          ],
        };
      });
      addTearDown(dio.close);

      final foods = await ApiFoodRepository(dio).searchFoods(query: '雞');

      expect(request.path, '/api/foods');
      expect(request.queryParameters['langCode'], 'zh-TW');
      expect(foods.single.nutritionPer100Grams.protein, 31);
    });
  });

  group('ApiDailyRecordRepository', () {
    test('新增紀錄會傳送餐別與 UTC 時間', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return null;
      });
      addTearDown(dio.close);
      final food = Food(
        id: 1,
        code: 'CHICKEN',
        name: '雞胸肉',
        description: '',
        nutritionPer100Grams: const NutritionSummary.zero(),
      );

      await ApiDailyRecordRepository(dio).addRecord(
        food: food,
        quantityGrams: 120,
        consumedAt: DateTime.parse('2026-07-27T12:00:00+08:00'),
        mealTypeCode: 'Lunch',
      );

      expect(request.path, '/api/daily-records');
      expect(request.data['foodId'], 1);
      expect(request.data['mealTypeCode'], 'Lunch');
      expect(request.data['consumedAt'], '2026-07-27T04:00:00.000Z');
    });
  });
}

Dio _dio(Object? Function(RequestOptions options) response) {
  final dio = Dio(BaseOptions(baseUrl: 'https://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<Object?>(
            requestOptions: options,
            statusCode: options.method == 'POST' ? 204 : 200,
            data: response(options),
          ),
        );
      },
    ),
  );
  return dio;
}
