import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_token_store.dart';
import '../domain/models/app_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_api.dart';
import 'dtos/auth_response_dto.dart';

/// 以 ASP.NET Core Identity API 實作正式身分驗證流程。
class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._authApi, this._tokenStore);

  final AuthApi _authApi;
  final AuthTokenStore _tokenStore;

  @override
  Future<AppUser> signIn({
    required String loginId,
    required String password,
  }) async {
    try {
      final response = await _authApi.signIn(
        loginId: loginId.trim(),
        password: password,
      );
      return _saveSession(response);
    } on ApiException catch (error) {
      _tokenStore.clear();
      throw _toAuthException(error);
    }
  }

  @override
  Future<AppUser> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authApi.register(
        userAccount: userAccount.trim(),
        displayName: displayName.trim(),
        email: email.trim(),
        password: password,
      );
      return _saveSession(response);
    } on ApiException catch (error) {
      _tokenStore.clear();
      throw _toAuthException(error);
    }
  }

  @override
  void signOut() {
    _tokenStore.clear();
  }

  AppUser _saveSession(AuthResponseDto response) {
    _tokenStore.save(response.toTokens());
    return response.user.toDomain();
  }

  static AuthException _toAuthException(ApiException error) {
    return AuthException(
      error.message,
      code: error.code,
      fieldErrors: {
        for (final entry in error.fieldErrors.entries)
          if (entry.value.isNotEmpty)
            entry.key: AuthFieldFailure(
              code: entry.value.first.code,
              message: entry.value.first.message,
              parameters: entry.value.first.parameters,
            ),
      },
      traceId: error.traceId,
    );
  }
}
