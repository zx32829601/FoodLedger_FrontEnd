import 'dtos/access_token_response_dto.dart';
import 'dtos/current_user_response_dto.dart';
import 'dtos/identity_info_response_dto.dart';

/// ASP.NET Core Identity 與目前使用者資訊的遠端資料來源邊界。
abstract interface class AuthApi {
  Future<void> register({required String email, required String password});

  Future<AccessTokenResponseDto> signIn({
    required String email,
    required String password,
  });

  Future<AccessTokenResponseDto> refresh({required String refreshToken});

  Future<CurrentUserResponseDto> getCurrentUser();

  Future<IdentityInfoResponseDto> getIdentityInfo();
}
