import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/api/api_client.dart';
import 'package:food_ledger_frontend/core/auth/auth_token_store.dart';

void main() {
  group('ApiClient', () {
    test('Cookie 模式不會把記憶體中的 Bearer Token 加入 request', () async {
      late RequestOptions recordedRequest;
      final tokenStore = AuthTokenStore()
        ..save(
          AuthTokens(
            tokenType: 'Bearer',
            accessToken: 'should-not-be-sent',
            refreshToken: 'test-refresh-token',
            expiresAt: DateTime.utc(2026, 7, 27),
          ),
        );
      final dio = Dio(BaseOptions(baseUrl: 'https://foodledger.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            recordedRequest = options;
            handler.resolve(
              Response<void>(requestOptions: options, statusCode: 200),
            );
          },
        ),
      );
      final client = ApiClient(
        tokenStore: tokenStore,
        dio: dio,
        useCookies: true,
      );
      addTearDown(client.close);

      await client.dio.get<void>('/api/users/me');

      expect(recordedRequest.headers.containsKey('Authorization'), isFalse);
    });

    test('受保護 API 回傳 401 時會通知 Session 統一登出', () async {
      var unauthorizedCount = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://foodledger.test'))
        ..httpClientAdapter = _UnauthorizedAdapter();
      final client = ApiClient(
        tokenStore: AuthTokenStore(),
        dio: dio,
        onUnauthorized: () => unauthorizedCount += 1,
      );
      addTearDown(client.close);

      await expectLater(
        client.dio.get<void>('/api/users/me'),
        throwsA(isA<DioException>()),
      );

      expect(unauthorizedCount, 1);
    });

    test('登入 API 的 401 僅代表憑證錯誤，不觸發 Session 失效通知', () async {
      var unauthorizedCount = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://foodledger.test'))
        ..httpClientAdapter = _UnauthorizedAdapter();
      final client = ApiClient(
        tokenStore: AuthTokenStore(),
        dio: dio,
        onUnauthorized: () => unauthorizedCount += 1,
        shouldNotifyUnauthorized: (request) =>
            request.uri.path != '/api/auth/login',
      );
      addTearDown(client.close);

      await expectLater(
        client.dio.post<void>('/api/auth/login'),
        throwsA(isA<DioException>()),
      );

      expect(unauthorizedCount, 0);
    });
  });
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'code': 'Auth.Unauthorized', 'message': '登入狀態已失效。'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
