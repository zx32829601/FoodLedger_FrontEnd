import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/api_body_measurement_repository.dart';
import '../../domain/models/body_measurement.dart';
import '../../domain/repositories/body_measurement_repository.dart';

final bodyMeasurementRepositoryProvider = Provider<BodyMeasurementRepository>((
  ref,
) {
  return ApiBodyMeasurementRepository(ref.watch(apiClientProvider).dio);
});

/// 畫面目前顯示的量測清單、分頁與本地日期篩選條件。
class BodyMeasurementHistoryState {
  const BodyMeasurementHistoryState({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    this.fromDate,
    this.toDate,
  });

  final List<BodyMeasurement> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final DateTime? fromDate;
  final DateTime? toDate;

  bool get hasNextPage => page * pageSize < totalCount;
}

/// 協調量測歷史的篩選、分頁與異動後重新載入。
class BodyMeasurementController
    extends AsyncNotifier<BodyMeasurementHistoryState> {
  static const _pageSize = 20;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Future<BodyMeasurementHistoryState> build() async {
    final userId = ref.watch(
      authenticationProvider.select((value) => value.user?.id),
    );
    if (userId == null) return _empty();
    return _loadPage(1);
  }

  Future<void> applyDateRange(DateTime? fromDate, DateTime? toDate) async {
    _fromDate = fromDate;
    _toDate = toDate;
    await reload();
  }

  Future<void> clearDateRange() => applyDateRange(null, null);

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(1));
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || !current.hasNextPage || state.isLoading) return;
    final next = await _loadPage(current.page + 1);
    state = AsyncData(
      BodyMeasurementHistoryState(
        items: List.unmodifiable([...current.items, ...next.items]),
        page: next.page,
        pageSize: next.pageSize,
        totalCount: next.totalCount,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );
  }

  Future<BodyMeasurement> create({
    required double weightInKilograms,
    double? bodyFatPercentage,
    double? muscleMassInKilograms,
  }) async {
    final result = await ref
        .read(bodyMeasurementRepositoryProvider)
        .create(
          weightInKilograms: weightInKilograms,
          bodyFatPercentage: bodyFatPercentage,
          muscleMassInKilograms: muscleMassInKilograms,
        );
    await reload();
    return result;
  }

  Future<BodyMeasurement> updateMeasurement(BodyMeasurement measurement) async {
    try {
      final result = await ref
          .read(bodyMeasurementRepositoryProvider)
          .update(measurement);
      await reload();
      return result;
    } on ApiException catch (error, stackTrace) {
      if (error.code == 'BodyMeasurement.Conflict') await reload();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<BodyMeasurementDeletionImpact> getDeletionImpact(int measurementId) =>
      ref
          .read(bodyMeasurementRepositoryProvider)
          .getDeletionImpact(measurementId);

  Future<void> delete(BodyMeasurementDeletionImpact impact) async {
    try {
      await ref
          .read(bodyMeasurementRepositoryProvider)
          .delete(
            measurementId: impact.measurementId,
            version: impact.version,
            impactToken: impact.impactToken,
          );
      await reload();
    } on ApiException catch (error, stackTrace) {
      if (error.code == 'BodyMeasurement.Conflict') await reload();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<BodyMeasurementHistoryState> _loadPage(int page) async {
    final result = await ref
        .read(bodyMeasurementRepositoryProvider)
        .getHistory(
          page: page,
          pageSize: _pageSize,
          fromDate: _fromDate,
          toDate: _toDate,
        );
    return BodyMeasurementHistoryState(
      items: result.items,
      page: result.page,
      pageSize: result.pageSize,
      totalCount: result.totalCount,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  BodyMeasurementHistoryState _empty() => BodyMeasurementHistoryState(
    items: const [],
    page: 1,
    pageSize: _pageSize,
    totalCount: 0,
    fromDate: _fromDate,
    toDate: _toDate,
  );
}

final bodyMeasurementProvider =
    AsyncNotifierProvider<
      BodyMeasurementController,
      BodyMeasurementHistoryState
    >(BodyMeasurementController.new);
