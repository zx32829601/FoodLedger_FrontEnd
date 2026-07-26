import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/api/api_exception.dart';
import 'package:food_ledger_frontend/core/auth/auth_token_store.dart';
import 'package:food_ledger_frontend/features/authentication/data/api_auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/data/auth_api.dart';
import 'package:food_ledger_frontend/features/authentication/data/dtos/auth_response_dto.dart';
import 'package:food_ledger_frontend/features/authentication/data/dtos/current_user_response_dto.dart';
import 'package:food_ledger_frontend/features/authentication/domain/repositories/auth_repository.dart';

void main() {
  group('ApiAuthRepository', () {
    test('既有 Cookie Session 有效時可從目前使用者 API 還原登入者', () async {
      final authApi = _FakeAuthApi();
      final repository = ApiAuthRepository(authApi, AuthTokenStore());

      final user = await repository.restoreSession();

      expect(user?.userAccount, 'member_account');
      expect(user?.displayName, '測試會員');
    });

    test('登入成功時保存 Token 並組合目前使用者資料', () async {
      final authApi = _FakeAuthApi();
      final tokenStore = AuthTokenStore();
      final repository = ApiAuthRepository(authApi, tokenStore);

      final user = await repository.signIn(
        loginId: ' member_account ',
        password: _validTestPassword(),
      );

      expect(tokenStore.accessToken, _testAccessToken());
      expect(user.id, '42');
      expect(user.userAccount, 'member_account');
      expect(user.displayName, '測試會員');
      expect(user.email, 'member@example.com');
      expect(user.isAdmin, isFalse);
      expect(authApi.receivedLoginId, 'member_account');
    });

    test('註冊成功時直接保存回應 Token 與使用者，不再呼叫舊登入端點', () async {
      final authApi = _FakeAuthApi();
      final tokenStore = AuthTokenStore();
      final repository = ApiAuthRepository(authApi, tokenStore);

      final user = await repository.register(
        userAccount: ' new_member ',
        displayName: ' 新會員 ',
        email: ' new.member@example.com ',
        password: _validTestPassword(),
      );

      expect(authApi.registerCallCount, 1);
      expect(authApi.signInCallCount, 0);
      expect(authApi.receivedUserAccount, 'new_member');
      expect(authApi.receivedDisplayName, '新會員');
      expect(authApi.receivedEmail, 'new.member@example.com');
      expect(tokenStore.accessToken, _testAccessToken());
      expect(user.displayName, '測試會員');
    });

    test('API 登入失敗時清除 Token 並轉換為 AuthException', () async {
      final authApi = _FakeAuthApi(
        signInError: const ApiException(
          message: '後端 fallback',
          code: 'Auth.InvalidCredentials',
        ),
      );
      final tokenStore = AuthTokenStore()
        ..save(
          AuthTokens(
            tokenType: 'Bearer',
            accessToken: _testAccessToken(),
            refreshToken: _testRefreshToken(),
            expiresAt: DateTime.utc(2026, 7, 22),
          ),
        );
      final repository = ApiAuthRepository(authApi, tokenStore);

      final request = repository.signIn(
        loginId: 'member_account',
        password: _validTestPassword(),
      );

      await expectLater(
        request,
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            '後端 fallback',
          ),
        ),
      );
      expect(tokenStore.tokens, isNull);
    });

    test('API 註冊欄位錯誤會保留給表單顯示', () async {
      final authApi = _FakeAuthApi(
        registerError: const ApiException(
          message: '此使用者帳號已被註冊',
          code: 'Auth.UserAccountAlreadyExists',
          traceId: 'register-trace-id',
          fieldErrors: {
            'userAccount': [
              ApiFieldError(
                code: 'Auth.UserAccountAlreadyExists',
                message: 'Backend fallback message',
              ),
            ],
          },
        ),
      );
      final repository = ApiAuthRepository(authApi, AuthTokenStore());

      final request = repository.register(
        userAccount: 'member_account',
        displayName: '測試會員',
        email: 'member@example.com',
        password: _validTestPassword(),
      );

      await expectLater(
        request,
        throwsA(
          isA<AuthException>()
              .having(
                (error) => error.fieldErrors['userAccount']?.code,
                'userAccount error code',
                'Auth.UserAccountAlreadyExists',
              )
              .having((error) => error.traceId, 'traceId', 'register-trace-id'),
        ),
      );
    });
  });
}

String _validTestPassword() {
  return ['A', 'a', ...List.filled(6, '1')].join();
}

String _testAccessToken() => List.filled(3, 'access').join('-');

String _testRefreshToken() => List.filled(3, 'refresh').join('-');

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({this.signInError, this.registerError});

  final ApiException? signInError;
  final ApiException? registerError;
  int registerCallCount = 0;
  int signInCallCount = 0;
  String? receivedLoginId;
  String? receivedUserAccount;
  String? receivedDisplayName;
  String? receivedEmail;

  @override
  Future<CurrentUserResponseDto> getCurrentUser() async {
    return const CurrentUserResponseDto(
      userId: 42,
      userAccount: 'member_account',
      displayName: '測試會員',
      email: 'member@example.com',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResponseDto> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  }) async {
    registerCallCount += 1;
    if (registerError case final error?) {
      throw error;
    }
    receivedUserAccount = userAccount;
    receivedDisplayName = displayName;
    receivedEmail = email;
    return _authResponse;
  }

  @override
  Future<AuthResponseDto> signIn({
    required String loginId,
    required String password,
  }) async {
    signInCallCount += 1;
    receivedLoginId = loginId;
    if (signInError case final error?) {
      throw error;
    }
    return _authResponse;
  }

  AuthResponseDto get _authResponse => AuthResponseDto(
    tokenType: 'Bearer',
    accessToken: _testAccessToken(),
    expiresIn: 3600,
    refreshToken: _testRefreshToken(),
    user: const CurrentUserResponseDto(
      userId: 42,
      userAccount: 'member_account',
      displayName: '測試會員',
      email: 'member@example.com',
    ),
  );
}
