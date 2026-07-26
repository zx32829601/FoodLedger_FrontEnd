import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'auth_api.dart';
import 'dtos/auth_response_dto.dart';
import 'dtos/current_user_response_dto.dart';

/// 使用 Dio 呼叫 FoodLedger 自訂 Auth API。
class AuthApiService implements AuthApi {
  const AuthApiService(this._dio);

  /// 建立 FoodLedger 使用者的正式 API 路徑。
  static const registerPath = '/api/auth/register';

  /// 驗證 FoodLedger 使用者的正式 API 路徑。
  static const loginPath = '/api/auth/login';

  /// 取得目前已登入使用者的正式 API 路徑。
  static const currentUserPath = '/api/users/me';

  final Dio _dio;

  @override
  Future<AuthResponseDto> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await _request(
      () => _dio.post<Object?>(
        registerPath,
        data: {
          'userAccount': userAccount,
          'displayName': displayName,
          'email': email,
          'password': password,
        },
      ),
    );
    return AuthResponseDto.fromJson(response.data);
  }

  @override
  Future<AuthResponseDto> signIn({
    required String loginId,
    required String password,
  }) async {
    final response = await _request(
      () => _dio.post<Object?>(
        loginPath,
        data: {'loginId': loginId, 'password': password},
      ),
    );
    return AuthResponseDto.fromJson(response.data);
  }

  @override
  Future<CurrentUserResponseDto> getCurrentUser() async {
    final response = await _request(() => _dio.get<Object?>(currentUserPath));
    return CurrentUserResponseDto.fromJson(response.data);
  }

  Future<Response<Object?>> _request(
    Future<Response<Object?>> Function() send,
  ) async {
    try {
      return await send();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
