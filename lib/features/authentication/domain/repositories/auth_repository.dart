import '../models/app_user.dart';

/// 隔離 Mock 與未來正式 Identity API 的身分驗證操作。
abstract interface class AuthRepository {
  Future<AppUser> signIn({required String loginId, required String password});

  Future<AppUser> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  });

  void signOut();
}

/// 可安全呈現在驗證介面的預期錯誤。
class AuthException implements Exception {
  const AuthException(
    this.message, {
    this.code,
    this.fieldErrors = const {},
    this.traceId,
  });

  final String message;
  final String? code;
  final Map<String, AuthFieldFailure> fieldErrors;
  final String? traceId;
}

/// Repository 保留的欄位錯誤契約，由 presentation layer 決定顯示文案。
class AuthFieldFailure {
  const AuthFieldFailure({
    required this.code,
    required this.message,
    this.parameters = const {},
  });

  final String code;
  final String message;
  final Map<String, Object?> parameters;
}
