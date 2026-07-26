import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/auth/auth_token_store.dart';
import 'package:food_ledger_frontend/features/authentication/data/mock_auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/domain/models/app_user.dart';
import 'package:food_ledger_frontend/features/authentication/domain/repositories/auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/presentation/providers/auth_providers.dart';

void main() {
  group('AuthenticationController', () {
    test('初始狀態為未登入', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authenticationProvider);

      expect(state.status, AuthenticationStatus.unauthenticated);
      expect(state.user, isNull);
    });

    test('登入後建立 Session 並可登出', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
      );
      addTearDown(container.dispose);
      final validPassword = ['A', 'a', ...List.filled(6, '1')].join();

      final succeeded = await container
          .read(authenticationProvider.notifier)
          .signIn(loginId: 'admin@example.com', password: validPassword);

      expect(succeeded, isTrue);
      expect(container.read(authenticationProvider).user?.isAdmin, isTrue);

      container.read(authenticationProvider.notifier).signOut();

      expect(
        container.read(authenticationProvider).status,
        AuthenticationStatus.unauthenticated,
      );
    });

    test('註冊欄位錯誤會保留在未登入狀態供表單顯示', () async {
      final repository = _FailingAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final succeeded = await container
          .read(authenticationProvider.notifier)
          .register(
            userAccount: 'existing_user',
            displayName: '測試會員',
            email: 'member@example.com',
            password: 'Password1',
          );

      final state = container.read(authenticationProvider);
      expect(succeeded, isFalse);
      expect(state.status, AuthenticationStatus.unauthenticated);
      expect(state.fieldErrors['userAccount'], '此使用者帳號已被註冊');
      expect(state.traceId, 'register-trace-id');
    });

    test('受保護 API 回傳 401 時清除 Token 並切回未登入狀態', () {
      final tokenStore = AuthTokenStore()
        ..save(
          AuthTokens(
            tokenType: 'Bearer',
            accessToken: List.filled(3, 'access').join('-'),
            refreshToken: List.filled(3, 'refresh').join('-'),
            expiresAt: DateTime.utc(2026, 7, 26),
          ),
        );
      const user = AppUser(
        id: 'member-1',
        userAccount: 'member',
        displayName: '測試會員',
        email: 'member@example.com',
        isAdmin: false,
      );
      final repository = _SignOutRecordingAuthRepository(tokenStore);
      final container = ProviderContainer(
        overrides: [
          authTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(repository),
          initialAuthUserProvider.overrideWithValue(user),
        ],
      );
      addTearDown(container.dispose);

      container.read(authenticationProvider.notifier).handleUnauthorized();

      final state = container.read(authenticationProvider);
      expect(tokenStore.tokens, isNull);
      expect(repository.signOutCallCount, 1);
      expect(state.status, AuthenticationStatus.unauthenticated);
      expect(state.errorMessage, '登入狀態已失效，請重新登入');
    });
  });
}

class _FailingAuthRepository implements AuthRepository {
  @override
  Future<AppUser> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  }) {
    throw const AuthException(
      '請確認輸入資料是否正確',
      code: 'Validation.Failed',
      fieldErrors: {
        'userAccount': AuthFieldFailure(
          code: 'Auth.UserAccountAlreadyExists',
          message: 'Backend fallback message',
        ),
      },
      traceId: 'register-trace-id',
    );
  }

  @override
  Future<AppUser> signIn({required String loginId, required String password}) {
    throw UnimplementedError();
  }

  @override
  void signOut() {}
}

class _SignOutRecordingAuthRepository implements AuthRepository {
  _SignOutRecordingAuthRepository(this._tokenStore);

  final AuthTokenStore _tokenStore;
  int signOutCallCount = 0;

  @override
  Future<AppUser> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signIn({required String loginId, required String password}) {
    throw UnimplementedError();
  }

  @override
  void signOut() {
    signOutCallCount += 1;
    _tokenStore.clear();
  }
}
