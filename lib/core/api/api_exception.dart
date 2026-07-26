import 'package:dio/dio.dart';

/// 已從 HTTP Client 細節轉換完成、可由 Repository 處理的 API 錯誤。
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.traceId,
  });

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseBody = _jsonObjectOrNull(error.response?.data);
    final fieldErrors = _readFieldErrors(responseBody?['errors']);
    final traceId = _stringOrNull(responseBody?['traceId']);

    if (_isConnectionFailure(error.type)) {
      return const ApiException(message: '無法連線至伺服器');
    }
    if (statusCode == 400) {
      return ApiException(
        message:
            _identityValidationMessage(fieldErrors.keys) ??
            fieldErrors.values.expand((messages) => messages).firstOrNull ??
            _stringOrNull(responseBody?['title']) ??
            '輸入資料格式不正確',
        statusCode: statusCode,
        fieldErrors: fieldErrors,
        traceId: traceId,
      );
    }
    if (statusCode == 401) {
      return ApiException(
        message: '電子郵件或密碼不正確',
        statusCode: statusCode,
        traceId: traceId,
      );
    }
    if (statusCode == 403) {
      return ApiException(
        message: '目前帳號沒有執行此操作的權限',
        statusCode: statusCode,
        traceId: traceId,
      );
    }
    if (statusCode == 404) {
      return ApiException(
        message: '找不到要求的資料',
        statusCode: statusCode,
        traceId: traceId,
      );
    }

    return ApiException(
      message: 'FoodLedger API 暫時無法處理要求，請稍後再試',
      statusCode: statusCode,
      traceId: traceId,
    );
  }

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;
  final String? traceId;

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

  static Map<String, List<String>> _readFieldErrors(Object? value) {
    final errors = _jsonObjectOrNull(value);
    if (errors == null) {
      return const {};
    }

    return {
      for (final entry in errors.entries)
        entry.key: switch (entry.value) {
          final List<Object?> messages => messages.whereType<String>().toList(
            growable: false,
          ),
          final String message => [message],
          _ => const <String>[],
        },
    };
  }

  static String? _stringOrNull(Object? value) {
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  static String? _identityValidationMessage(Iterable<String> errorCodes) {
    const messages = {
      'DuplicateUserName': '此電子郵件已被註冊',
      'DuplicateEmail': '此電子郵件已被註冊',
      'InvalidEmail': '請輸入有效的電子郵件',
      'PasswordTooShort': '密碼長度不足',
      'PasswordRequiresDigit': '密碼至少需要一個數字',
      'PasswordRequiresLower': '密碼至少需要一個英文小寫字母',
      'PasswordRequiresUpper': '密碼至少需要一個英文大寫字母',
      'PasswordRequiresNonAlphanumeric': '密碼至少需要一個特殊字元',
    };
    for (final errorCode in errorCodes) {
      if (messages[errorCode] case final message?) {
        return message;
      }
    }
    return null;
  }
}
