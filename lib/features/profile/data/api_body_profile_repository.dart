import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/api/antiforgery_request.dart';
import '../../../core/api/api_exception.dart';
import '../domain/models/body_profile.dart';
import '../domain/models/body_profile_option.dart';
import '../domain/repositories/body_profile_repository.dart';

/// 使用 Body Profile 與 DefinedCode API 讀寫身體資料畫面所需內容。
class ApiBodyProfileRepository implements BodyProfileRepository {
  ApiBodyProfileRepository(this._dio);

  final Dio _dio;

  @override
  Future<BodyProfile?> getProfile({
    required String langCode,
    Future<void>? cancelWhen,
  }) async {
    final cancelToken = _cancelOn(cancelWhen);
    try {
      final response = await _dio.get<Object?>(
        '/api/me/body-profile',
        queryParameters: {'langCode': langCode},
        cancelToken: cancelToken,
      );
      return _mapProfile(Map<String, Object?>.from(response.data! as Map));
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) throw _sessionChanged;
      final exception = ApiException.fromDio(error);
      if (exception.code == 'BodyProfile.NotFound') return null;
      throw exception;
    }
  }

  @override
  Future<BodyProfile> saveProfile(
    BodyProfile profile, {
    Future<void>? cancelWhen,
  }) async {
    final cancelToken = _cancelOn(cancelWhen);
    try {
      final response = await _dio.put<Object?>(
        '/api/me/body-profile',
        options: await antiforgeryRequestOptions(
          _dio,
          cancelToken: cancelToken,
        ),
        cancelToken: cancelToken,
        data: {
          'birthDate': _dateValue(profile.birthDate),
          'biologicalSexCode': profile.biologicalSexCode,
          'heightInCentimeters': profile.heightInCentimeters,
          'fitnessGoalCode': profile.fitnessGoalCode,
          'activityLevelCode': profile.activityLevelCode,
          'timeZone': profile.timeZone.trim(),
          'version': profile.version,
        },
      );
      return _mapProfile(Map<String, Object?>.from(response.data! as Map));
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) throw _sessionChanged;
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<BodyProfileOption>> getFitnessGoals({required String langCode}) =>
      _getOptions('/api/defined-codes/fitness-goals', langCode);

  @override
  Future<List<BodyProfileOption>> getActivityLevels({
    required String langCode,
  }) => _getOptions('/api/defined-codes/activity-levels', langCode);

  Future<List<BodyProfileOption>> _getOptions(
    String path,
    String langCode,
  ) async {
    try {
      final response = await _dio.get<List<Object?>>(
        path,
        queryParameters: {'langCode': langCode},
      );
      final options =
          [
            for (final item in response.data ?? const [])
              _mapOption(Map<String, Object?>.from(item! as Map)),
          ]..sort((left, right) {
            final order = left.sortOrder.compareTo(right.sortOrder);
            return order != 0 ? order : left.code.compareTo(right.code);
          });
      return List.unmodifiable(options);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static BodyProfile _mapProfile(Map<String, Object?> json) => BodyProfile(
    birthDate: DateTime.parse(json['birthDate']! as String),
    biologicalSexCode: json['biologicalSexCode']! as String,
    heightInCentimeters: (json['heightInCentimeters'] as num).toDouble(),
    fitnessGoalCode: json['fitnessGoalCode']! as String,
    activityLevelCode: json['activityLevelCode']! as String,
    timeZone: json['timeZone']! as String,
    version: json['version']! as String,
    fitnessGoalDisplayName: json['fitnessGoalDisplayName'] as String?,
    fitnessGoalLangCode: json['fitnessGoalLangCode'] as String?,
    fitnessGoalNote: json['fitnessGoalNote'] as String?,
    activityLevelDisplayName: json['activityLevelDisplayName'] as String?,
    activityLevelLangCode: json['activityLevelLangCode'] as String?,
    activityLevelNote: json['activityLevelNote'] as String?,
  );

  static BodyProfileOption _mapOption(Map<String, Object?> json) =>
      BodyProfileOption(
        code: json['code']! as String,
        displayName: json['displayName']! as String,
        sortOrder: (json['sortOrder'] as num).toInt(),
        langCode: json['langCode'] as String?,
        note: json['note'] as String?,
      );

  static String _dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static CancelToken? _cancelOn(Future<void>? cancelWhen) {
    if (cancelWhen == null) return null;
    final token = CancelToken();
    unawaited(cancelWhen.then((_) => token.cancel('登入使用者已變更')));
    return token;
  }

  static const _sessionChanged = ApiException(
    message: '登入使用者已變更，已取消原本的操作。',
    code: 'Auth.SessionChanged',
    statusCode: 401,
  );
}
