import '../models/body_measurement.dart';

/// 定義身體量測歷史所需的查詢與異動操作。
abstract interface class BodyMeasurementRepository {
  Future<BodyMeasurementPage> getHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<BodyMeasurement> create({
    required double weightInKilograms,
    double? bodyFatPercentage,
    double? muscleMassInKilograms,
  });

  Future<BodyMeasurement> update(BodyMeasurement measurement);

  Future<BodyMeasurementDeletionImpact> getDeletionImpact(int measurementId);

  Future<void> delete({
    required int measurementId,
    required String version,
    required String impactToken,
  });
}
