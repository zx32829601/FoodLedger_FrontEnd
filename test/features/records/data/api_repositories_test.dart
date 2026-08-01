import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/data/api_daily_record_repository.dart';
import 'package:food_ledger_frontend/features/records/data/api_defined_code_repository.dart';
import 'package:food_ledger_frontend/features/records/data/api_food_repository.dart';
import 'package:food_ledger_frontend/features/records/data/api_nutrition_repository.dart';
import 'package:food_ledger_frontend/features/records/domain/models/food.dart';

void main() {
  group('ApiFoodRepository', () {
    test('搜尋結果會保留分頁、英文副標與熱量摘要', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return {
          'items': [
            {
              'foodId': 1,
              'foodCode': 'CHICKEN',
              'displayName': '雞胸肉',
              'langCode': 'zh-TW',
              'englishName': 'Chicken Breast',
              'caloriesPer100Grams': 165,
            },
          ],
          'page': 2,
          'pageSize': 20,
          'totalCount': 43,
        };
      });
      addTearDown(dio.close);

      final result = await ApiFoodRepository(
        dio,
      ).searchFoods(query: '雞', langCode: 'zh-TW', page: 2, pageSize: 20);

      expect(request.path, '/api/foods');
      expect(request.queryParameters['langCode'], 'zh-TW');
      expect(request.queryParameters['page'], 2);
      expect(result.totalCount, 43);
      expect(result.items.single.englishName, 'Chicken Breast');
      expect(result.items.single.caloriesPer100Grams, 165);
    });

    test('食物明細會轉換分類與依序營養素', () async {
      final dio = _dio(
        (_) => {
          'foodId': 1,
          'foodCode': 'CHICKEN',
          'displayName': '雞胸肉',
          'langCode': 'zh-TW',
          'englishName': 'Chicken Breast',
          'description': '低脂蛋白質來源',
          'categories': [
            {
              'categoryId': 7,
              'code': 'MEAT',
              'displayName': '肉類',
              'langCode': 'zh-TW',
            },
          ],
          'nutrients': [
            {
              'code': 'Protein',
              'displayName': '蛋白質',
              'langCode': 'zh-TW',
              'displayOrder': 20,
              'amountPer100Grams': 31,
              'unitCode': 'g',
            },
          ],
        },
      );
      addTearDown(dio.close);

      final food = await ApiFoodRepository(
        dio,
      ).getFoodDetail(foodId: 1, langCode: 'zh-TW');

      expect(food.englishName, 'Chicken Breast');
      expect(food.categories.single.displayName, '肉類');
      expect(food.nutrientPer100Grams('Protein')?.displayOrder, 20);
    });

    test('空白查詢仍會向 API 載入全部食物', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return {'items': <Object?>[]};
      });
      addTearDown(dio.close);

      final foods = await ApiFoodRepository(
        dio,
      ).searchFoods(query: '   ', langCode: 'zh-TW', page: 1, pageSize: 20);

      expect(request.path, '/api/foods');
      expect(request.queryParameters['query'], '');
      expect(foods.items, isEmpty);
    });
  });

  group('ApiDailyRecordRepository', () {
    test('查詢紀錄會使用與營養摘要相同的時區與語系', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return <Object?>[
          {
            'recordId': 11,
            'foodId': 1,
            'food': {
              'foodId': 1,
              'foodCode': 'CHICKEN',
              'displayName': 'Chicken',
              'langCode': 'en-US',
            },
            'quantityInGrams': 120,
            'consumedAt': '2026-07-28T04:00:00Z',
            'mealTypeCode': 'Lunch',
            'note': null,
            'nutrients': [
              {
                'nutrientId': 2,
                'code': 'Protein',
                'displayName': 'Protein',
                'langCode': 'en-US',
                'amount': 37.2,
                'unitCode': 'g',
              },
            ],
          },
        ];
      });
      addTearDown(dio.close);

      final records = await ApiDailyRecordRepository(dio).getRecordsForDate(
        DateTime(2026, 7, 28),
        timeZone: 'Asia/Taipei',
        langCode: 'zh-TW',
      );

      expect(request.path, '/api/daily-records');
      expect(request.queryParameters, {
        'date': '2026-07-28',
        'timeZone': 'Asia/Taipei',
        'langCode': 'zh-TW',
      });
      expect(records.single.food.langCode, 'en-US');
      expect(records.single.nutrient('Protein')?.displayName, 'Protein');
      expect(records.single.nutrient('Protein')?.amount, 37.2);
      expect(records.single.nutrient('Calories'), isNull);
    });

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
        langCode: 'zh-TW',
        nutrientsPer100Grams: const [],
      );

      await ApiDailyRecordRepository(dio).addRecord(
        food: food,
        quantityGrams: 120,
        consumedAt: DateTime.parse('2026-07-27T12:00:00+08:00'),
        mealTypeCode: 'Lunch',
      );

      expect(request.path, '/api/daily-records');
      expect(request.data['foodId'], 1);
      expect(request.data['quantityInGrams'], 120);
      expect(request.data.containsKey('quantity'), isFalse);
      expect(request.data['mealTypeCode'], 'Lunch');
      expect(request.data['consumedAt'], '2026-07-27T04:00:00.000Z');
    });

    test('更新紀錄只使用 quantityInGrams 契約', () async {
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
        langCode: 'zh-TW',
        nutrientsPer100Grams: const [],
      );

      await ApiDailyRecordRepository(dio).updateRecord(
        recordId: 11,
        food: food,
        quantityGrams: 135,
        consumedAt: DateTime.parse('2026-07-27T12:00:00+08:00'),
        mealTypeCode: 'Lunch',
      );

      expect(request.path, '/api/daily-records/11');
      expect(request.data['quantityInGrams'], 135);
      expect(request.data.containsKey('quantity'), isFalse);
    });
  });

  group('ApiDefinedCodeRepository', () {
    test('餐別選項完整保留後端 DefinedCode 契約與排序', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return <Object?>[
          {
            'code': 'Lunch',
            'displayName': 'Lunch',
            'langCode': 'en-US',
            'note': 'Midday meal.',
            'sortOrder': 2,
          },
          {
            'code': 'Brunch',
            'displayName': 'Brunch',
            'langCode': 'en-US',
            'note': 'Late morning meal.',
            'sortOrder': 1,
          },
        ];
      });
      addTearDown(dio.close);

      final options = await ApiDefinedCodeRepository(
        dio,
      ).getMealTypes(langCode: 'en-US');

      expect(request.path, '/api/defined-codes/meal-types');
      expect(request.queryParameters['langCode'], 'en-US');
      expect(options.map((option) => option.code), ['Brunch', 'Lunch']);
      expect(options.first.displayName, 'Brunch');
      expect(options.first.langCode, 'en-US');
      expect(options.first.note, 'Late morning meal.');
      expect(options.first.sortOrder, 1);
    });
  });

  group('ApiNutritionRepository', () {
    test('每日摘要送出時區語系並保留動態營養素與餐別', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return {
          'date': '2026-07-28',
          'timeZone': 'Asia/Taipei',
          'totals': [
            {
              'nutrientId': 1,
              'code': 'Protein',
              'displayName': '蛋白質',
              'langCode': 'zh-TW',
              'amount': 31.5,
              'unitCode': 'g',
            },
          ],
          'mealTypes': [
            {
              'mealTypeCode': 'Lunch',
              'totals': [
                {
                  'nutrientId': 1,
                  'code': 'Protein',
                  'displayName': '蛋白質',
                  'langCode': 'zh-TW',
                  'amount': 20,
                  'unitCode': 'g',
                },
              ],
            },
          ],
        };
      });
      addTearDown(dio.close);

      final summary = await ApiNutritionRepository(dio).getDailySummary(
        date: DateTime(2026, 7, 28),
        timeZone: 'Asia/Taipei',
        langCode: 'zh-TW',
      );

      expect(request.path, '/api/nutrition-summary/daily');
      expect(request.queryParameters, {
        'date': '2026-07-28',
        'timeZone': 'Asia/Taipei',
        'langCode': 'zh-TW',
      });
      expect(summary.nutrient('Protein')?.displayName, '蛋白質');
      expect(summary.nutrient('Protein')?.amount, 31.5);
      expect(summary.mealTypes.single.mealTypeCode, 'Lunch');
      expect(summary.mealTypes.single.nutrient('Protein')?.amount, 20);
    });

    test('每週摘要保留週一到週日七天資料', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return {
          'startDate': '2026-07-27',
          'endDate': '2026-08-02',
          'timeZone': 'Asia/Taipei',
          'totals': [
            {
              'nutrientId': 2,
              'code': 'Calories',
              'displayName': '熱量',
              'langCode': 'zh-TW',
              'amount': 2100,
              'unitCode': 'kcal',
            },
          ],
          'days': [
            for (var index = 0; index < 7; index++)
              {
                'date': DateTime(
                  2026,
                  7,
                  27 + index,
                ).toIso8601String().substring(0, 10),
                'totals': <Object?>[],
              },
          ],
        };
      });
      addTearDown(dio.close);

      final summary = await ApiNutritionRepository(dio).getWeeklySummary(
        date: DateTime(2026, 7, 29),
        timeZone: 'Asia/Taipei',
        langCode: 'zh-TW',
      );

      expect(request.path, '/api/nutrition-summary/weekly');
      expect(request.queryParameters['date'], '2026-07-29');
      expect(request.queryParameters['timeZone'], 'Asia/Taipei');
      expect(request.queryParameters['langCode'], 'zh-TW');
      expect(summary.startDate, DateTime(2026, 7, 27));
      expect(summary.endDate, DateTime(2026, 8, 2));
      expect(summary.days, hasLength(7));
      expect(summary.nutrient('Calories')?.amount, 2100);
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
