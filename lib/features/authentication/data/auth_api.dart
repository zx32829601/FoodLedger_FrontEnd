import 'dtos/auth_response_dto.dart';
import 'dtos/current_user_response_dto.dart';

/// FoodLedger 自訂 Auth API 與目前使用者資訊的遠端資料來源邊界。
abstract interface class AuthApi {
  Future<AuthResponseDto> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  });

  Future<AuthResponseDto> signIn({
    required String loginId,
    required String password,
  });

  Future<CurrentUserResponseDto> getCurrentUser();
}
