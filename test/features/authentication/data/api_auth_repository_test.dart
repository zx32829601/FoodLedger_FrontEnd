import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/api/api_exception.dart';
import 'package:food_ledger_frontend/core/auth/auth_token_store.dart';
import 'package:food_ledger_frontend/features/authentication/data/api_auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/data/auth_api.dart';
import 'package:food_ledger_frontend/features/authentication/data/dtos/access_token_response_dto.dart';
import 'package:food_ledger_frontend/features/authentication/data/dtos/current_user_response_dto.dart';
import 'package:food_ledger_frontend/features/authentication/data/dtos/identity_info_response_dto.dart';
import 'package:food_ledger_frontend/features/authentication/domain/repositories/auth_repository.dart';

void main() {
  group('ApiAuthRepository', () {
    test('登入成功時保存 Token 並組合目前使用者資料', () async {
      final authApi = _FakeAuthApi();
      final tokenStore = AuthTokenStore();
      final repository = ApiAuthRepository(authApi, tokenStore);

      final user = await repository.signIn(
        email: 'member@example.com',
        password: _validTestPassword(),
      );

      expect(tokenStore.accessToken, _testAccessToken());
      expect(user.id, '42');
      expect(user.displayName, 'member@example.com');
      expect(user.email, 'member@example.com');
      expect(user.isAdmin, isFalse);
    });

    test('註冊成功後會自動登入並取得目前使用者', () async {
      final authApi = _FakeAuthApi();
      final repository = ApiAuthRepository(authApi, AuthTokenStore());

      await repository.register(
        email: 'member@example.com',
        password: _validTestPassword(),
      );

      expect(authApi.registerCallCount, 1);
      expect(authApi.signInCallCount, 1);
    });

    test('API 登入失敗時清除 Token 並轉換為 AuthException', () async {
      final authApi = _FakeAuthApi(
        signInError: const ApiException(message: '登入失敗'),
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
        email: 'member@example.com',
        password: _validTestPassword(),
      );

      await expectLater(
        request,
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            '登入失敗',
          ),
        ),
      );
      expect(tokenStore.tokens, isNull);
    });
  });
}

String _validTestPassword() {
  return ['A', 'a', ...List.filled(6, '1')].join();
}

String _testAccessToken() => List.filled(3, 'access').join('-');

String _testRefreshToken() => List.filled(3, 'refresh').join('-');

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({this.signInError});

  final ApiException? signInError;
  int registerCallCount = 0;
  int signInCallCount = 0;

  @override
  Future<CurrentUserResponseDto> getCurrentUser() async {
    return const CurrentUserResponseDto(
      userId: 42,
      userName: 'member@example.com',
      isAuthenticated: true,
    );
  }

  @override
  Future<IdentityInfoResponseDto> getIdentityInfo() async {
    return const IdentityInfoResponseDto(
      email: 'member@example.com',
      isEmailConfirmed: false,
    );
  }

  @override
  Future<AccessTokenResponseDto> refresh({required String refreshToken}) async {
    return _tokenResponse;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    registerCallCount += 1;
  }

  @override
  Future<AccessTokenResponseDto> signIn({
    required String email,
    required String password,
  }) async {
    signInCallCount += 1;
    if (signInError case final error?) {
      throw error;
    }
    return _tokenResponse;
  }

  AccessTokenResponseDto get _tokenResponse => AccessTokenResponseDto(
    tokenType: 'Bearer',
    accessToken: _testAccessToken(),
    expiresIn: 3600,
    refreshToken: _testRefreshToken(),
  );
}
