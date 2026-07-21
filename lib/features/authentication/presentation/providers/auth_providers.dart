import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
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
  });

  const AuthenticationState.unauthenticated({this.errorMessage})
    : status = AuthenticationStatus.unauthenticated,
      user = null;

  const AuthenticationState.authenticating()
    : status = AuthenticationStatus.authenticating,
      user = null,
      errorMessage = null;

  const AuthenticationState.authenticated(AppUser authenticatedUser)
    : status = AuthenticationStatus.authenticated,
      user = authenticatedUser,
      errorMessage = null;

  final AuthenticationStatus status;
  final AppUser? user;
  final String? errorMessage;

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

  Future<bool> signIn({required String email, required String password}) async {
    state = const AuthenticationState.authenticating();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      state = AuthenticationState.authenticated(user);
      return true;
    } on AuthException catch (error) {
      state = AuthenticationState.unauthenticated(errorMessage: error.message);
      return false;
    } catch (_) {
      state = const AuthenticationState.unauthenticated(
        errorMessage: '目前無法登入，請稍後再試',
      );
      return false;
    }
  }

  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    state = const AuthenticationState.authenticating();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .register(displayName: displayName, email: email, password: password);
      state = AuthenticationState.authenticated(user);
      return true;
    } on AuthException catch (error) {
      state = AuthenticationState.unauthenticated(errorMessage: error.message);
      return false;
    } catch (_) {
      state = const AuthenticationState.unauthenticated(
        errorMessage: '目前無法註冊，請稍後再試',
      );
      return false;
    }
  }

  void clearError() {
    if (!state.isAuthenticated && state.errorMessage != null) {
      state = const AuthenticationState.unauthenticated();
    }
  }

  void signOut() {
    state = const AuthenticationState.unauthenticated();
  }
}

final authenticationProvider =
    NotifierProvider<AuthenticationController, AuthenticationState>(
      AuthenticationController.new,
    );
