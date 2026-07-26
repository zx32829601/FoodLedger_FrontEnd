import '../domain/models/app_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Prototype 階段使用的記憶體身分驗證資料來源。
class MockAuthRepository implements AuthRepository {
  static const _requestDelay = Duration(milliseconds: 450);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_requestDelay);
    final normalizedEmail = email.trim().toLowerCase();
    if (!_isValidEmail(normalizedEmail) || password.length < 8) {
      throw const AuthException('電子郵件或密碼不正確');
    }

    return _createUser(
      email: normalizedEmail,
      displayName: _displayNameFromEmail(normalizedEmail),
    );
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_requestDelay);
    final normalizedEmail = email.trim().toLowerCase();
    if (!_isValidEmail(normalizedEmail) || password.length < 8) {
      throw const AuthException('註冊資料格式不正確，請重新確認');
    }

    return _createUser(
      email: normalizedEmail,
      displayName: _displayNameFromEmail(normalizedEmail),
    );
  }

  @override
  void signOut() {}

  AppUser _createUser({required String email, required String displayName}) {
    return AppUser(
      id: 'mock-${email.hashCode.abs()}',
      displayName: displayName,
      email: email,
      isAdmin: email.startsWith('admin@'),
    );
  }

  static bool _isValidEmail(String email) {
    final atIndex = email.indexOf('@');
    return atIndex > 0 &&
        atIndex < email.length - 3 &&
        email.indexOf('.', atIndex) > atIndex + 1;
  }

  static String _displayNameFromEmail(String email) {
    final account = email.split('@').first;
    if (account.isEmpty) {
      return 'FoodLedger 使用者';
    }
    return account[0].toUpperCase() + account.substring(1);
  }
}
