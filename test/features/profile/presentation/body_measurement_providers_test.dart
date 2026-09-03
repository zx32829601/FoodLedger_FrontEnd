import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/authentication/data/mock_auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/domain/models/app_user.dart';
import 'package:food_ledger_frontend/features/authentication/presentation/providers/auth_providers.dart';
import 'package:food_ledger_frontend/features/profile/domain/models/body_measurement.dart';
import 'package:food_ledger_frontend/features/profile/domain/repositories/body_measurement_repository.dart';
import 'package:food_ledger_frontend/features/profile/presentation/providers/body_measurement_providers.dart';

void main() {
  test('預設載入全部資料，套用與清除日期篩選會回到第一頁', () async {
    final repository = _Measurements();
    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(bodyMeasurementProvider.future);
    expect(repository.queries.single.fromDate, isNull);

    await container
        .read(bodyMeasurementProvider.notifier)
        .applyDateRange(DateTime(2026, 9, 1), DateTime(2026, 9, 3));
    expect(repository.queries.last.page, 1);
    expect(repository.queries.last.fromDate, DateTime(2026, 9, 1));

    await container.read(bodyMeasurementProvider.notifier).clearDateRange();
    expect(repository.queries.last.fromDate, isNull);
    expect(container.read(bodyMeasurementProvider).value?.fromDate, isNull);
  });

  test('新增後重新取得第一頁以包含後端產生的 measuredAt', () async {
    final repository = _Measurements();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(bodyMeasurementProvider.future);

    final created = await container
        .read(bodyMeasurementProvider.notifier)
        .create(weightInKilograms: 70.5);

    expect(created.measuredAt, DateTime.utc(2026, 9, 3, 2));
    expect(repository.queries.length, 2);
  });
}

ProviderContainer _container(BodyMeasurementRepository repository) =>
    ProviderContainer(
      overrides: [
        initialAuthUserProvider.overrideWithValue(
          const AppUser(
            id: 'user-a',
            userAccount: 'user_a',
            displayName: '使用者 A',
            email: 'user_a@example.com',
            isAdmin: false,
          ),
        ),
        restoreSessionOnStartProvider.overrideWithValue(false),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        bodyMeasurementRepositoryProvider.overrideWithValue(repository),
      ],
    );

typedef _Query = ({int page, DateTime? fromDate, DateTime? toDate});

class _Measurements implements BodyMeasurementRepository {
  final queries = <_Query>[];

  @override
  Future<BodyMeasurementPage> getHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    queries.add((page: page, fromDate: fromDate, toDate: toDate));
    return BodyMeasurementPage(
      items: [_measurement],
      page: page,
      pageSize: pageSize,
      totalCount: 1,
    );
  }

  @override
  Future<BodyMeasurement> create({
    required double weightInKilograms,
    double? bodyFatPercentage,
    double? muscleMassInKilograms,
  }) async => _measurement;

  @override
  Future<void> delete({
    required int measurementId,
    required String version,
    required String impactToken,
  }) async {}

  @override
  Future<BodyMeasurementDeletionImpact> getDeletionImpact(
    int measurementId,
  ) async => BodyMeasurementDeletionImpact(
    measurementId: measurementId,
    version: 'version-1',
    affectedSnapshotCount: 0,
    affectsCurrentTarget: false,
    expiresAt: DateTime.utc(2026, 9, 3, 3),
    impactToken: 'token',
  );

  @override
  Future<BodyMeasurement> update(BodyMeasurement measurement) async =>
      measurement;
}

final _measurement = BodyMeasurement(
  measurementId: 1,
  weightInKilograms: 70.5,
  measuredAt: DateTime.utc(2026, 9, 3, 2),
  version: 'version-1',
);
