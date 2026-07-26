import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/api/api_exception.dart';

void main() {
  group('ApiException', () {
    test('400 code-first 驗證錯誤會保留欄位代碼、參數與 Trace ID', () {
      final exception = DioException(
        requestOptions: RequestOptions(path: '/api/auth/register'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/api/auth/register'),
          statusCode: 400,
          data: {
            'code': 'Validation.Failed',
            'message': '請確認輸入資料是否正確。',
            'traceId': 'trace-id',
            'errors': {
              'password': [
                {
                  'code': 'Auth.PasswordInvalid',
                  'message': '密碼格式不正確。',
                  'parameters': {'minLength': 8},
                },
              ],
            },
          },
        ),
      );

      final result = ApiException.fromDio(exception);

      expect(result.statusCode, 400);
      expect(result.code, 'Validation.Failed');
      expect(result.message, '請確認輸入資料是否正確。');
      expect(
        result.fieldErrors['password']?.single.code,
        'Auth.PasswordInvalid',
      );
      expect(result.fieldErrors['password']?.single.message, '密碼格式不正確。');
      expect(result.fieldErrors['password']?.single.parameters['minLength'], 8);
      expect(result.traceId, 'trace-id');
    });

    test('401 Auth.InvalidCredentials 會保留後端 fallback 交由 Repository 翻譯', () {
      final exception = DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 401,
          data: {
            'code': 'Auth.InvalidCredentials',
            'message': '後端 fallback',
            'traceId': 'login-trace-id',
          },
        ),
      );

      final result = ApiException.fromDio(exception);

      expect(result.code, 'Auth.InvalidCredentials');
      expect(result.message, '後端 fallback');
      expect(result.traceId, 'login-trace-id');
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
