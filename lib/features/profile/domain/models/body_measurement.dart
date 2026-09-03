/// 單筆身體量測紀錄，以及後端提供的樂觀鎖定版本。
class BodyMeasurement {
  const BodyMeasurement({
    required this.measurementId,
    required this.weightInKilograms,
    required this.measuredAt,
    required this.version,
    this.bodyFatPercentage,
    this.muscleMassInKilograms,
  });

  final int measurementId;
  final double weightInKilograms;
  final double? bodyFatPercentage;
  final double? muscleMassInKilograms;
  final DateTime measuredAt;
  final String version;
}

/// 身體量測歷史的單頁結果。
class BodyMeasurementPage {
  const BodyMeasurementPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final List<BodyMeasurement> items;
  final int page;
  final int pageSize;
  final int totalCount;

  bool get hasNextPage => page * pageSize < totalCount;
}

/// 刪除前由後端簽署的影響預覽。
class BodyMeasurementDeletionImpact {
  const BodyMeasurementDeletionImpact({
    required this.measurementId,
    required this.version,
    required this.affectedSnapshotCount,
    required this.affectsCurrentTarget,
    required this.expiresAt,
    required this.impactToken,
  });

  final int measurementId;
  final String version;
  final int affectedSnapshotCount;
  final bool affectsCurrentTarget;
  final DateTime expiresAt;
  final String impactToken;
}
