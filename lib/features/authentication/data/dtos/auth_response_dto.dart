import '../../../../core/api/api_exception.dart';
import '../../../../core/api/json_object.dart';
import '../../../../core/auth/auth_token_store.dart';
import 'current_user_response_dto.dart';

/// FoodLedger 自訂註冊與登入 API 回傳的 Token 與使用者資料。
class AuthResponseDto {
  const AuthResponseDto({
    required this.tokenType,
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Object? value) {
    final json = requireJsonObject(value);
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final expiresIn = json['expiresIn'];
    if (accessToken is! String ||
        refreshToken is! String ||
        expiresIn is! num) {
      throw const ApiException(message: '登入 Token 回應格式不正確');
    }

    return AuthResponseDto(
      tokenType: json['tokenType'] is String
          ? json['tokenType']! as String
          : 'Bearer',
      accessToken: accessToken,
      expiresIn: expiresIn.toInt(),
      refreshToken: refreshToken,
      user: CurrentUserResponseDto.fromJson(json['user']),
    );
  }

  final String tokenType;
  final String accessToken;
  final int expiresIn;
  final String refreshToken;
  final CurrentUserResponseDto user;

  AuthTokens toTokens({DateTime? issuedAt}) {
    final issuedAtUtc = (issuedAt ?? DateTime.now()).toUtc();
    return AuthTokens(
      tokenType: tokenType,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: issuedAtUtc.add(Duration(seconds: expiresIn)),
    );
  }
}
