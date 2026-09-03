import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/profile/data/api_body_measurement_repository.dart';

void main() {
  test('GET 傳送分頁與日期條件並完整映射量測資料', () async {
    late RequestOptions request;
    final dio = _dio((options) {
      request = options;
      return {
        'items': [
          {
            'measurementId': 7,
            'weightInKilograms': 72.5,
            'bodyFatPercentage': 18.2,
            'muscleMassInKilograms': null,
            'measuredAt': '2026-09-03T01:30:00Z',
            'version': 'version-7',
          },
        ],
        'page': 2,
        'pageSize': 20,
        'totalCount': 25,
      };
    });
    addTearDown(dio.close);

    final result = await ApiBodyMeasurementRepository(dio).getHistory(
      page: 2,
      fromDate: DateTime(2026, 8, 1),
      toDate: DateTime(2026, 9, 3),
    );

    expect(request.path, '/api/me/body-measurements');
    expect(request.queryParameters, {
      'page': 2,
      'pageSize': 20,
      'fromDate': '2026-08-01',
      'toDate': '2026-09-03',
    });
    expect(result.items.single.measurementId, 7);
    expect(result.items.single.bodyFatPercentage, 18.2);
    expect(result.items.single.muscleMassInKilograms, isNull);
    expect(result.hasNextPage, isFalse);
  });

  test('DELETE 使用 impact 回應的 version 與 token', () async {
    late RequestOptions request;
    final dio = _dio((options) {
      request = options;
      return null;
    });
    addTearDown(dio.close);

    await ApiBodyMeasurementRepository(dio).delete(
      measurementId: 9,
      version: 'version-9',
      impactToken: 'signed-token',
    );

    expect(request.method, 'DELETE');
    expect(request.path, '/api/me/body-measurements/9');
    expect(request.data, {
      'version': 'version-9',
      'impactToken': 'signed-token',
    });
  });
}

Dio _dio(Object? Function(RequestOptions options) response) {
  final dio = Dio(BaseOptions(baseUrl: 'https://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: response(options),
        ),
      ),
    ),
  );
  return dio;
}
