import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_token_store.dart';
import '../../data/api_auth_repository.dart';
import '../../data/auth_api.dart';
import '../../data/auth_api_service.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../auth_strings.dart';

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return AuthTokenStore();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    tokenStore: ref.watch(authTokenStoreProvider),
    onUnauthorized: () {
      ref.read(authenticationProvider.notifier).handleUnauthorized();
    },
    shouldNotifyUnauthorized: (request) {
      final path = request.uri.path;
      return path != AuthApiService.loginPath &&
          path != AuthApiService.registerPath;
    },
  );
  ref.onDispose(client.close);
  return client;
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApiService(ref.watch(apiClientProvider).dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(
    ref.watch(authApiProvider),
    ref.watch(authTokenStoreProvider),
  );
});

/// 預留給未來從 Cookie 或安全儲存還原登入狀態，也方便測試注入。
final initialAuthUserProvider = Provider<AppUser?>((ref) => null);

enum AuthenticationStatus { unauthenticated, authenticating, authenticated }

/// 應用程式唯一可信的登入 Session 狀態。
class AuthenticationState {
  const AuthenticationState({
    required this.status,
    this.user,
    this.errorMessage,
    this.fieldErrors = const {},
    this.traceId,
  });

  const AuthenticationState.unauthenticated({
    this.errorMessage,
    this.fieldErrors = const {},
    this.traceId,
  }) : status = AuthenticationStatus.unauthenticated,
       user = null;

  const AuthenticationState.authenticating()
    : status = AuthenticationStatus.authenticating,
      user = null,
      errorMessage = null,
      fieldErrors = const {},
      traceId = null;

  const AuthenticationState.authenticated(AppUser authenticatedUser)
    : status = AuthenticationStatus.authenticated,
      user = authenticatedUser,
      errorMessage = null,
      fieldErrors = const {},
      traceId = null;

  final AuthenticationStatus status;
  final AppUser? user;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final String? traceId;

  bool get isAuthenticated => status == AuthenticationStatus.authenticated;
  bool get isAuthenticating => status == AuthenticationStatus.authenticating;
}

class AuthenticationController extends Notifier<AuthenticationState> {
  @override
  AuthenticationState build() {
    final initialUser = ref.watch(initialAuthUserProvider);
    return initialUser == null
        ? const AuthenticationState.unauthenticated()
        : AuthenticationState.authenticated(initialUser);
  }

  Future<bool> signIn({required String loginId, required String password}) {
    return _authenticate(
      operation: () => ref
          .read(authRepositoryProvider)
          .signIn(loginId: loginId, password: password),
      unexpectedErrorMessage: AuthStrings.loginUnavailable,
    );
  }

  Future<bool> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  }) {
    return _authenticate(
      operation: () => ref
          .read(authRepositoryProvider)
          .register(
            userAccount: userAccount,
            displayName: displayName,
            email: email,
            password: password,
          ),
      unexpectedErrorMessage: AuthStrings.registerUnavailable,
    );
  }

  Future<bool> _authenticate({
    required Future<AppUser> Function() operation,
    required String unexpectedErrorMessage,
  }) async {
    state = const AuthenticationState.authenticating();
    try {
      final user = await operation();
      state = AuthenticationState.authenticated(user);
      return true;
    } on AuthException catch (error) {
      state = AuthenticationState.unauthenticated(
        errorMessage: AuthStrings.errorMessage(
          code: error.code,
          fallback: error.message,
        ),
        fieldErrors: {
          for (final entry in error.fieldErrors.entries)
            entry.key: AuthStrings.fieldErrorMessage(entry.value),
        },
        traceId: error.traceId,
      );
      return false;
    } catch (_) {
      state = AuthenticationState.unauthenticated(
        errorMessage: unexpectedErrorMessage,
      );
      return false;
    }
  }

  void clearError() {
    if (!state.isAuthenticated &&
        (state.errorMessage != null || state.fieldErrors.isNotEmpty)) {
      state = const AuthenticationState.unauthenticated();
    }
  }

  void signOut() {
    ref.read(authRepositoryProvider).signOut();
    state = const AuthenticationState.unauthenticated();
  }

  void handleUnauthorized() {
    ref.read(authRepositoryProvider).signOut();
    state = const AuthenticationState.unauthenticated(
      errorMessage: AuthStrings.sessionExpired,
    );
  }
}

final authenticationProvider =
    NotifierProvider<AuthenticationController, AuthenticationState>(
      AuthenticationController.new,
    );
