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
  Future<BodyProfile?> getProfile() async {
    try {
      final response = await _dio.get<Object?>('/api/me/body-profile');
      return _mapProfile(Map<String, Object?>.from(response.data! as Map));
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);
      if (exception.code == 'BodyProfile.NotFound') return null;
      throw exception;
    }
  }

  @override
  Future<BodyProfile> saveProfile(BodyProfile profile) async {
    try {
      final response = await _dio.put<Object?>(
        '/api/me/body-profile',
        options: await antiforgeryRequestOptions(_dio),
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
}
