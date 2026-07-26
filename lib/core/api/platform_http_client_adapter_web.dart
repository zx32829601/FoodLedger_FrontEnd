import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// 讓 Flutter Web 跨來源 request 可攜帶後端設定的 HttpOnly Cookie。
void configurePlatformHttpClientAdapter(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
