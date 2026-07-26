import 'package:dio/dio.dart';

import '../auth/auth_token_store.dart';
import 'api_config.dart';

/// 建立具備共用逾時與 Bearer Token 注入能力的 Dio Client。
class ApiClient {
  ApiClient({required AuthTokenStore tokenStore, Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final accessToken = tokenStore.accessToken;
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;

  void close() {
    dio.close();
  }
}
