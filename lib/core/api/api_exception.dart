import 'package:dio/dio.dart';

/// 單一 API 欄位錯誤，保留穩定代碼、fallback 訊息與多語系插值參數。
class ApiFieldError {
  const ApiFieldError({
    required this.code,
    required this.message,
    this.parameters = const {},
  });

  final String code;
  final String message;
  final Map<String, Object?> parameters;
}

/// 已從 HTTP Client 細節轉換完成、可由 Repository 處理的 API 錯誤。
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors = const {},
    this.traceId,
    this.parameters = const {},
  });

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseBody = _jsonObjectOrNull(error.response?.data);
    final code = _stringOrNull(responseBody?['code']);
    final fieldErrors = _readFieldErrors(responseBody?['errors']);
    final traceId = _stringOrNull(responseBody?['traceId']);
    final parameters =
        _jsonObjectOrNull(responseBody?['parameters']) ?? const {};

    if (_isConnectionFailure(error.type)) {
      return const ApiException(message: '無法連線至伺服器');
    }
    if (statusCode == 400) {
      return ApiException(
        message:
            _stringOrNull(responseBody?['message']) ??
            fieldErrors.values
                .expand((errors) => errors)
                .firstOrNull
                ?.message ??
            '輸入資料格式不正確',
        code: code,
        statusCode: statusCode,
        fieldErrors: fieldErrors,
        traceId: traceId,
        parameters: parameters,
      );
    }
    if (statusCode == 401) {
      return ApiException(
        message: _stringOrNull(responseBody?['message']) ?? '登入狀態已失效，請重新登入',
        code: code,
        statusCode: statusCode,
        traceId: traceId,
        parameters: parameters,
      );
    }
    if (statusCode == 403) {
      return ApiException(
        message: '目前帳號沒有執行此操作的權限',
        code: code,
        statusCode: statusCode,
        traceId: traceId,
        parameters: parameters,
      );
    }
    if (statusCode == 404) {
      return ApiException(
        message: _stringOrNull(responseBody?['message']) ?? '找不到要求的資料',
        code: code,
        statusCode: statusCode,
        traceId: traceId,
        parameters: parameters,
      );
    }

    return ApiException(
      message:
          _stringOrNull(responseBody?['message']) ??
          'FoodLedger API 暫時無法處理要求，請稍後再試',
      code: code,
      statusCode: statusCode,
      traceId: traceId,
      parameters: parameters,
    );
  }

  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, List<ApiFieldError>> fieldErrors;
  final String? traceId;
  final Map<String, Object?> parameters;

  static bool _isConnectionFailure(DioExceptionType type) {
    return type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout;
  }

  static Map<String, Object?>? _jsonObjectOrNull(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  static Map<String, List<ApiFieldError>> _readFieldErrors(Object? value) {
    final errors = _jsonObjectOrNull(value);
    if (errors == null) {
      return const {};
    }

    return {
      for (final entry in errors.entries)
        entry.key: switch (entry.value) {
          final List<Object?> values =>
            values
                .map((value) => _readFieldError(value))
                .nonNulls
                .toList(growable: false),
          final String message => [
            ApiFieldError(code: 'Validation.InvalidValue', message: message),
          ],
          _ => const <ApiFieldError>[],
        },
    };
  }

  static ApiFieldError? _readFieldError(Object? value) {
    if (value is String) {
      return ApiFieldError(code: 'Validation.InvalidValue', message: value);
    }

    final json = _jsonObjectOrNull(value);
    final code = _stringOrNull(json?['code']);
    final message = _stringOrNull(json?['message']);
    if (code == null || message == null) {
      return null;
    }

    return ApiFieldError(
      code: code,
      message: message,
      parameters: _jsonObjectOrNull(json?['parameters']) ?? const {},
    );
  }

  static String? _stringOrNull(Object? value) {
    return value is String && value.trim().isNotEmpty ? value : null;
  }
}
