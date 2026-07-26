import '../../../../core/api/api_exception.dart';
import '../../../../core/api/json_object.dart';
import '../../domain/models/app_user.dart';

/// `GET /api/users/me` 回傳的目前登入使用者資料。
class CurrentUserResponseDto {
  const CurrentUserResponseDto({
    required this.userId,
    required this.userAccount,
    required this.displayName,
    required this.email,
  });

  factory CurrentUserResponseDto.fromJson(Object? value) {
    final json = requireJsonObject(value);
    final userId = json['userId'];
    final userAccount = json['userAccount'];
    final displayName = json['displayName'];
    final email = json['email'];
    if (userId is! num ||
        userAccount is! String ||
        displayName is! String ||
        email is! String) {
      throw const ApiException(message: '使用者資料回應格式不正確');
    }

    return CurrentUserResponseDto(
      userId: userId.toInt(),
      userAccount: userAccount,
      displayName: displayName,
      email: email,
    );
  }

  final int userId;
  final String userAccount;
  final String displayName;
  final String email;

  AppUser toDomain() {
    return AppUser(
      id: userId.toString(),
      userAccount: userAccount,
      displayName: displayName,
      email: email,
      // 目前 Auth API 尚未回傳角色；管理功能仍由後端 policy 保護。
      isAdmin: false,
    );
  }
}
