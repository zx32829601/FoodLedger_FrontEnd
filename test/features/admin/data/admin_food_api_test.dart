import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/admin/data/admin_food_api.dart';

void main() {
  test('營養素目錄會傳送 LangCode 並保留翻譯與單位', () async {
    late RequestOptions request;
    final dio = Dio(BaseOptions(baseUrl: 'https://localhost'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'nutrientId': 1,
                  'code': 'Protein',
                  'displayName': '蛋白質',
                  'langCode': 'zh-TW',
                  'unitCode': 'g',
                },
              ],
            ),
          );
        },
      ),
    );
    addTearDown(dio.close);

    final nutrients = await ApiAdminFoodRepository(
      dio,
    ).getNutrients(langCode: 'zh-TW');

    expect(request.path, '/api/nutrients');
    expect(request.queryParameters['langCode'], 'zh-TW');
    expect(nutrients.single.code, 'Protein');
    expect(nutrients.single.displayName, '蛋白質');
    expect(nutrients.single.unitCode, 'g');
  });
}
