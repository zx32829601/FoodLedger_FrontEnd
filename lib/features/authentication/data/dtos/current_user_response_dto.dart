import '../../../../core/api/api_exception.dart';
import '../../../../core/api/json_object.dart';

/// `GET /api/users/me` 回傳的目前登入使用者資料。
class CurrentUserResponseDto {
  const CurrentUserResponseDto({
    required this.userId,
    required this.userName,
    required this.isAuthenticated,
  });

  factory CurrentUserResponseDto.fromJson(Object? value) {
    final json = requireJsonObject(value);
    final userId = json['userId'];
    final isAuthenticated = json['isAuthenticated'];
    if (userId is! num || isAuthenticated is! bool) {
      throw const ApiException(message: '使用者資料回應格式不正確');
    }

    return CurrentUserResponseDto(
      userId: userId.toInt(),
      userName: json['userName'] is String ? json['userName']! as String : null,
      isAuthenticated: isAuthenticated,
    );
  }

  final int userId;
  final String? userName;
  final bool isAuthenticated;
}
