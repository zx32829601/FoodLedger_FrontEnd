import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/api/api_client.dart';
import 'package:food_ledger_frontend/core/auth/auth_token_store.dart';

void main() {
  group('ApiClient', () {
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
