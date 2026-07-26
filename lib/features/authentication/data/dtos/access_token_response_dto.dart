import '../../../../core/api/api_exception.dart';
import '../../../../core/api/json_object.dart';
import '../../../../core/auth/auth_token_store.dart';

/// ASP.NET Core Identity `/login` 與 `/refresh` 的 Token 回應。
class AccessTokenResponseDto {
  const AccessTokenResponseDto({
    required this.tokenType,
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
  });

  factory AccessTokenResponseDto.fromJson(Object? value) {
    final json = requireJsonObject(value);
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final expiresIn = json['expiresIn'];
    if (accessToken is! String ||
        refreshToken is! String ||
        expiresIn is! num) {
      throw const ApiException(message: '登入 Token 回應格式不正確');
    }

    return AccessTokenResponseDto(
      tokenType: json['tokenType'] is String
          ? json['tokenType']! as String
          : 'Bearer',
      accessToken: accessToken,
      expiresIn: expiresIn.toInt(),
      refreshToken: refreshToken,
    );
  }

  final String tokenType;
  final String accessToken;
  final int expiresIn;
  final String refreshToken;

  AuthTokens toDomain({DateTime? issuedAt}) {
    final issuedAtUtc = (issuedAt ?? DateTime.now()).toUtc();
    return AuthTokens(
      tokenType: tokenType,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: issuedAtUtc.add(Duration(seconds: expiresIn)),
    );
  }
}
