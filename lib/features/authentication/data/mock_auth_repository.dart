import '../domain/models/app_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Prototype 階段使用的記憶體身分驗證資料來源。
class MockAuthRepository implements AuthRepository {
  static const _requestDelay = Duration(milliseconds: 450);

  @override
  Future<AppUser> signIn({
    required String loginId,
    required String password,
  }) async {
    await Future<void>.delayed(_requestDelay);
    final normalizedLoginId = loginId.trim().toLowerCase();
    final isEmail = normalizedLoginId.contains('@');
    if ((isEmail
            ? !_isValidEmail(normalizedLoginId)
            : !_isValidUserAccount(normalizedLoginId)) ||
        password.length < 8) {
      throw const AuthException(
        'Invalid credentials.',
        code: 'Auth.InvalidCredentials',
      );
    }

    final email = isEmail
        ? normalizedLoginId
        : '$normalizedLoginId@example.com';
    final userAccount = isEmail
        ? normalizedLoginId.split('@').first
        : normalizedLoginId;
    return _createUser(
      userAccount: userAccount,
      email: email,
      displayName: _displayNameFromEmail(email),
    );
  }

  @override
  Future<AppUser> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_requestDelay);
    final normalizedUserAccount = userAccount.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedDisplayName = displayName.trim();
    if (!_isValidUserAccount(normalizedUserAccount) ||
        trimmedDisplayName.isEmpty ||
        !_isValidEmail(normalizedEmail) ||
        password.length < 8) {
      throw const AuthException(
        'Registration data is invalid.',
        code: 'Validation.Failed',
      );
    }

    return _createUser(
      userAccount: normalizedUserAccount,
      email: normalizedEmail,
      displayName: trimmedDisplayName,
    );
  }

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<void> signOut() async {}

  AppUser _createUser({
    required String userAccount,
    required String email,
    required String displayName,
  }) {
    return AppUser(
      id: 'mock-${email.hashCode.abs()}',
      userAccount: userAccount,
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

  static bool _isValidUserAccount(String userAccount) {
    return RegExp(r'^[a-z0-9_-]{4,30}$').hasMatch(userAccount);
  }

  static String _displayNameFromEmail(String email) {
    final account = email.split('@').first;
    if (account.isEmpty) {
      return 'FoodLedger 使用者';
    }
    return account[0].toUpperCase() + account.substring(1);
  }
}
