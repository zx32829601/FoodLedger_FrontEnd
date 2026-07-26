import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_token_store.dart';
import 'api_config.dart';
import 'platform_http_client_adapter.dart';

/// 建立具備共用逾時與 Bearer Token 注入能力的 Dio Client。
class ApiClient {
  ApiClient({
    required AuthTokenStore tokenStore,
    Dio? dio,
    this.useCookies = kIsWeb,
    void Function()? onUnauthorized,
    bool Function(RequestOptions request)? shouldNotifyUnauthorized,
  }) : dio =
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
    if (dio == null) {
      configurePlatformHttpClientAdapter(this.dio);
    }
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final accessToken = tokenStore.accessToken;
          if (!useCookies && accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401 &&
              (shouldNotifyUnauthorized?.call(error.requestOptions) ?? true)) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final bool useCookies;

  void close() {
    dio.close();
  }
}
