import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/authentication/data/auth_api_service.dart';

void main() {
  group('AuthApiService', () {
    test('註冊使用 FoodLedger 自訂端點與完整 request 契約', () async {
      late RequestOptions recordedRequest;
      final dio = Dio(BaseOptions(baseUrl: 'https://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            recordedRequest = options;
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: _authResponseJson(),
              ),
            );
          },
        ),
      );
      addTearDown(dio.close);
      final service = AuthApiService(dio);

      final response = await service.register(
        userAccount: 'food_user',
        displayName: 'Food 使用者',
        email: 'user@example.com',
        password: 'Password1',
      );

      expect(recordedRequest.method, 'POST');
      expect(recordedRequest.path, '/api/auth/register');
      expect(recordedRequest.data, {
        'userAccount': 'food_user',
        'displayName': 'Food 使用者',
        'email': 'user@example.com',
        'password': 'Password1',
      });
      expect(response.user.userAccount, 'food_user');
    });

    test('登入使用 FoodLedger 自訂端點並傳送 loginId', () async {
      late RequestOptions recordedRequest;
      final dio = Dio(BaseOptions(baseUrl: 'https://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            recordedRequest = options;
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: _authResponseJson(),
              ),
            );
          },
        ),
      );
      addTearDown(dio.close);
      final service = AuthApiService(dio);

      await service.signIn(loginId: 'food_user', password: 'Password1');

      expect(recordedRequest.method, 'POST');
      expect(recordedRequest.path, '/api/auth/login');
      expect(recordedRequest.data, {
        'loginId': 'food_user',
        'password': 'Password1',
      });
    });
  });
}

Map<String, Object?> _authResponseJson() {
  return {
    'accessToken': 'test-access-token',
    'refreshToken': 'test-refresh-token',
    'expiresIn': 3600,
    'user': {
      'userId': 42,
      'userAccount': 'food_user',
      'displayName': 'Food 使用者',
      'email': 'user@example.com',
    },
  };
}
