import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_token_store.dart';
import '../domain/models/app_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_api.dart';

/// 以 ASP.NET Core Identity API 實作正式身分驗證流程。
class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._authApi, this._tokenStore);

  final AuthApi _authApi;
  final AuthTokenStore _tokenStore;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final tokenResponse = await _authApi.signIn(
        email: email.trim(),
        password: password,
      );
      _tokenStore.save(tokenResponse.toDomain());
      return await _loadCurrentUser();
    } on ApiException catch (error) {
      _tokenStore.clear();
      throw AuthException(error.message);
    }
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
  }) async {
    try {
      await _authApi.register(email: email.trim(), password: password);
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
    return signIn(email: email, password: password);
  }

  @override
  void signOut() {
    _tokenStore.clear();
  }

  Future<AppUser> _loadCurrentUser() async {
    final currentUser = await _authApi.getCurrentUser();
    final identityInfo = await _authApi.getIdentityInfo();
    if (!currentUser.isAuthenticated) {
      throw const ApiException(message: '後端未建立有效的登入狀態');
    }

    final userName = currentUser.userName?.trim();
    final accountName = identityInfo.email.split('@').first;
    return AppUser(
      id: currentUser.userId.toString(),
      displayName: userName == null || userName.isEmpty
          ? accountName
          : userName,
      email: identityInfo.email,
      // 現有 API 尚未回傳角色；管理功能必須等後端提供受保護的角色資訊。
      isAdmin: false,
    );
  }
}
