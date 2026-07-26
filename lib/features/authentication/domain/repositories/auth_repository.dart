import '../models/app_user.dart';

/// 隔離 Mock 與未來正式 Identity API 的身分驗證操作。
abstract interface class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({required String email, required String password});

  void signOut();
}

/// 可安全呈現在驗證介面的預期錯誤。
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}
