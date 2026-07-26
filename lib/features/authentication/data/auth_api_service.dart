import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'auth_api.dart';
import 'dtos/access_token_response_dto.dart';
import 'dtos/current_user_response_dto.dart';
import 'dtos/identity_info_response_dto.dart';

/// 使用 Dio 呼叫 ASP.NET Core Identity API。
class AuthApiService implements AuthApi {
  const AuthApiService(this._dio);

  final Dio _dio;

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _request(
      () => _dio.post<Object?>(
        '/register',
        data: {'email': email, 'password': password},
      ),
    );
  }

  @override
  Future<AccessTokenResponseDto> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _request(
      () => _dio.post<Object?>(
        '/login',
        data: {'email': email, 'password': password},
      ),
    );
    return AccessTokenResponseDto.fromJson(response.data);
  }

  @override
  Future<AccessTokenResponseDto> refresh({required String refreshToken}) async {
    final response = await _request(
      () =>
          _dio.post<Object?>('/refresh', data: {'refreshToken': refreshToken}),
    );
    return AccessTokenResponseDto.fromJson(response.data);
  }

  @override
  Future<CurrentUserResponseDto> getCurrentUser() async {
    final response = await _request(() => _dio.get<Object?>('/api/users/me'));
    return CurrentUserResponseDto.fromJson(response.data);
  }

  @override
  Future<IdentityInfoResponseDto> getIdentityInfo() async {
    final response = await _request(() => _dio.get<Object?>('/manage/info'));
    return IdentityInfoResponseDto.fromJson(response.data);
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
