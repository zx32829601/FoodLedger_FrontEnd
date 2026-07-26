import '../../../../core/api/api_exception.dart';
import '../../../../core/api/json_object.dart';
import '../../../../core/auth/auth_token_store.dart';
import 'current_user_response_dto.dart';

/// FoodLedger 自訂註冊與登入 API 回傳的 Token 與使用者資料。
class AuthResponseDto {
  const AuthResponseDto({
    this.tokenType,
    this.accessToken,
    this.expiresIn,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Object? value) {
    final json = requireJsonObject(value);
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final expiresIn = json['expiresIn'];
    final hasAnyTokenValue =
        accessToken != null || refreshToken != null || expiresIn != null;
    final hasCompleteTokenValue =
        accessToken is String && refreshToken is String && expiresIn is num;
    if (hasAnyTokenValue && !hasCompleteTokenValue) {
      throw const ApiException(message: '登入 Token 回應格式不正確');
    }

    return AuthResponseDto(
      tokenType: hasCompleteTokenValue
          ? (json['tokenType'] is String
                ? json['tokenType']! as String
                : 'Bearer')
          : null,
      accessToken: accessToken as String?,
      expiresIn: (expiresIn as num?)?.toInt(),
      refreshToken: refreshToken as String?,
      user: CurrentUserResponseDto.fromJson(json['user']),
    );
  }

  final String? tokenType;
  final String? accessToken;
  final int? expiresIn;
  final String? refreshToken;
  final CurrentUserResponseDto user;

  AuthTokens? toTokens({DateTime? issuedAt}) {
    final tokenType = this.tokenType;
    final accessToken = this.accessToken;
    final refreshToken = this.refreshToken;
    final expiresIn = this.expiresIn;
    if (tokenType == null ||
        accessToken == null ||
        refreshToken == null ||
        expiresIn == null) {
      return null;
    }
    final issuedAtUtc = (issuedAt ?? DateTime.now()).toUtc();
    return AuthTokens(
      tokenType: tokenType,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: issuedAtUtc.add(Duration(seconds: expiresIn)),
    );
  }
}
