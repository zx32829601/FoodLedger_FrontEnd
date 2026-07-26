import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import 'auth_api.dart';
import 'dtos/auth_response_dto.dart';
import 'dtos/current_user_response_dto.dart';

/// 使用 Dio 呼叫 FoodLedger 自訂 Auth API。
class AuthApiService implements AuthApi {
  AuthApiService(this._dio, {this.useCookies = kIsWeb});

  /// 建立 FoodLedger 使用者的正式 API 路徑。
  static const registerPath = '/api/auth/register';

  /// 驗證 FoodLedger 使用者的正式 API 路徑。
  static const loginPath = '/api/auth/login';

  /// 取得目前已登入使用者的正式 API 路徑。
  static const currentUserPath = '/api/users/me';

  /// 清除目前 Web Identity Cookie 的正式 API 路徑。
  static const logoutPath = '/api/auth/logout';

  /// 取得 Cookie 狀態變更 request 使用的 Antiforgery Token。
  static const antiforgeryPath = '/api/auth/antiforgery';

  final Dio _dio;
  final bool useCookies;

  String? _antiforgeryToken;

  @override
  Future<AuthResponseDto> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await _authenticate(
      () => _dio.post<Object?>(
        registerPath,
        queryParameters: useCookies ? {'useCookies': true} : null,
        options: _cookieRequestOptions(),
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
    final response = await _authenticate(
      () => _dio.post<Object?>(
        loginPath,
        queryParameters: useCookies ? {'useCookies': true} : null,
        options: _cookieRequestOptions(),
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

  @override
  Future<void> signOut() async {
    if (!useCookies) {
      return;
    }
    await _refreshAntiforgeryToken();
    await _request(
      () => _dio.post<Object?>(logoutPath, options: _cookieRequestOptions()),
    );
    _antiforgeryToken = null;
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

  Future<Response<Object?>> _authenticate(
    Future<Response<Object?>> Function() send,
  ) async {
    if (useCookies) {
      await _refreshAntiforgeryToken();
    }

    final response = await _request(send);

    if (useCookies) {
      await _refreshAntiforgeryToken();
    }
    return response;
  }

  Future<void> _refreshAntiforgeryToken() async {
    final response = await _request(() => _dio.get<Object?>(antiforgeryPath));
    final data = response.data;
    if (data is! Map || data['requestToken'] is! String) {
      throw const ApiException(message: 'Antiforgery Token 回應格式不正確');
    }
    _antiforgeryToken = data['requestToken']! as String;
  }

  Options? _cookieRequestOptions() {
    if (!useCookies || _antiforgeryToken == null) {
      return null;
    }
    return Options(headers: {'X-CSRF-TOKEN': _antiforgeryToken});
  }
}
