import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/api/api_exception.dart';

void main() {
  group('ApiException', () {
    test('400 ValidationProblem 會保留欄位錯誤與 Trace ID', () {
      final exception = DioException(
        requestOptions: RequestOptions(path: '/register'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/register'),
          statusCode: 400,
          data: {
            'title': 'Validation failed',
            'traceId': 'trace-id',
            'errors': {
              'PasswordRequiresDigit': ['Password requires a digit.'],
            },
          },
        ),
      );

      final result = ApiException.fromDio(exception);

      expect(result.statusCode, 400);
      expect(result.message, '密碼至少需要一個數字');
      expect(result.fieldErrors['PasswordRequiresDigit'], [
        'Password requires a digit.',
      ]);
      expect(result.traceId, 'trace-id');
    });

    test('連線錯誤會轉換成可理解的 API 無法連線訊息', () {
      final exception = DioException(
        requestOptions: RequestOptions(path: '/login'),
        type: DioExceptionType.connectionError,
      );

      final result = ApiException.fromDio(exception);

      expect(result.statusCode, isNull);
      expect(result.message, contains('無法連線'));
    });
  });
}
