import '../../../../core/api/api_exception.dart';
import '../../../../core/api/json_object.dart';

/// `GET /manage/info` 回傳的 ASP.NET Core Identity 帳號資料。
class IdentityInfoResponseDto {
  const IdentityInfoResponseDto({
    required this.email,
    required this.isEmailConfirmed,
  });

  factory IdentityInfoResponseDto.fromJson(Object? value) {
    final json = requireJsonObject(value);
    final email = json['email'];
    final isEmailConfirmed = json['isEmailConfirmed'];
    if (email is! String || isEmailConfirmed is! bool) {
      throw const ApiException(message: 'Identity 帳號回應格式不正確');
    }

    return IdentityInfoResponseDto(
      email: email,
      isEmailConfirmed: isEmailConfirmed,
    );
  }

  final String email;
  final bool isEmailConfirmed;
}
