import 'package:dio/dio.dart';

import '../../../core/api/antiforgery_request.dart';
import '../../../core/api/api_exception.dart';
import '../domain/models/body_measurement.dart';
import '../domain/repositories/body_measurement_repository.dart';

/// 使用目前登入者的 Body Measurement API 管理量測紀錄。
class ApiBodyMeasurementRepository implements BodyMeasurementRepository {
  ApiBodyMeasurementRepository(this._dio);

  final Dio _dio;
  static const _path = '/api/me/body-measurements';

  @override
  Future<BodyMeasurementPage> getHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        _path,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (fromDate != null) 'fromDate': _dateValue(fromDate),
          if (toDate != null) 'toDate': _dateValue(toDate),
        },
      );
      final json = Map<String, Object?>.from(response.data! as Map);
      return BodyMeasurementPage(
        items: List.unmodifiable([
          for (final item in json['items']! as List<Object?>)
            _mapMeasurement(Map<String, Object?>.from(item! as Map)),
        ]),
        page: (json['page'] as num).toInt(),
        pageSize: (json['pageSize'] as num).toInt(),
        totalCount: (json['totalCount'] as num).toInt(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<BodyMeasurement> create({
    required double weightInKilograms,
    double? bodyFatPercentage,
    double? muscleMassInKilograms,
  }) => _mutate(
    _path,
    data: _values(weightInKilograms, bodyFatPercentage, muscleMassInKilograms),
  );

  @override
  Future<BodyMeasurement> update(BodyMeasurement measurement) => _mutate(
    '$_path/${measurement.measurementId}',
    isUpdate: true,
    data: {
      ..._values(
        measurement.weightInKilograms,
        measurement.bodyFatPercentage,
        measurement.muscleMassInKilograms,
      ),
      'version': measurement.version,
    },
  );

  @override
  Future<BodyMeasurementDeletionImpact> getDeletionImpact(
    int measurementId,
  ) async {
    try {
      final response = await _dio.get<Object?>(
        '$_path/$measurementId/deletion-impact',
      );
      final json = Map<String, Object?>.from(response.data! as Map);
      return BodyMeasurementDeletionImpact(
        measurementId: (json['measurementId'] as num).toInt(),
        version: json['version']! as String,
        affectedSnapshotCount: (json['affectedSnapshotCount'] as num).toInt(),
        affectsCurrentTarget: json['affectsCurrentTarget']! as bool,
        expiresAt: DateTime.parse(json['expiresAt']! as String),
        impactToken: json['impactToken']! as String,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> delete({
    required int measurementId,
    required String version,
    required String impactToken,
  }) async {
    try {
      await _dio.delete<Object?>(
        '$_path/$measurementId',
        options: await antiforgeryRequestOptions(_dio),
        data: {'version': version, 'impactToken': impactToken},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<BodyMeasurement> _mutate(
    String path, {
    required Map<String, Object?> data,
    bool isUpdate = false,
  }) async {
    try {
      final options = await antiforgeryRequestOptions(_dio);
      final response = isUpdate
          ? await _dio.put<Object?>(path, data: data, options: options)
          : await _dio.post<Object?>(path, data: data, options: options);
      return _mapMeasurement(Map<String, Object?>.from(response.data! as Map));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static Map<String, Object?> _values(
    double weight,
    double? bodyFat,
    double? muscleMass,
  ) => {
    'weightInKilograms': weight,
    'bodyFatPercentage': bodyFat,
    'muscleMassInKilograms': muscleMass,
  };

  static BodyMeasurement _mapMeasurement(Map<String, Object?> json) =>
      BodyMeasurement(
        measurementId: (json['measurementId'] as num).toInt(),
        weightInKilograms: (json['weightInKilograms'] as num).toDouble(),
        bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
        muscleMassInKilograms: (json['muscleMassInKilograms'] as num?)
            ?.toDouble(),
        measuredAt: DateTime.parse(json['measuredAt']! as String),
        version: json['version']! as String,
      );

  static String _dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
