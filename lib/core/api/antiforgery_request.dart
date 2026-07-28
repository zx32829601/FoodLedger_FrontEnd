import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

/// 為 Flutter Web 的 Cookie mutation 取得最新 Antiforgery Token。
Future<Options?> antiforgeryRequestOptions(Dio dio) async {
  if (!kIsWeb) return null;

  try {
    final response = await dio.get<Object?>('/api/auth/antiforgery');
    final data = response.data;
    if (data is! Map || data['requestToken'] is! String) {
      throw const ApiException(message: 'Antiforgery Token 回應格式不正確');
    }
    return Options(headers: {'X-CSRF-TOKEN': data['requestToken']});
  } on DioException catch (error) {
    throw ApiException.fromDio(error);
  }
}
