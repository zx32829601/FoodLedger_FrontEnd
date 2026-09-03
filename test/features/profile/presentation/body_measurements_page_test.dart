import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/authentication/data/mock_auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/domain/models/app_user.dart';
import 'package:food_ledger_frontend/features/authentication/presentation/providers/auth_providers.dart';
import 'package:food_ledger_frontend/features/profile/domain/models/body_measurement.dart';
import 'package:food_ledger_frontend/features/profile/domain/repositories/body_measurement_repository.dart';
import 'package:food_ledger_frontend/features/profile/presentation/body_measurements_page.dart';
import 'package:food_ledger_frontend/features/profile/presentation/providers/body_measurement_providers.dart';

void main() {
  testWidgets('預設顯示全部紀錄並提供相鄰的編輯與紅色刪除操作', (tester) async {
    await tester.pumpWidget(_app(_Measurements()));
    await tester.pumpAndSettle();

    expect(find.text('目前顯示全部量測紀錄'), findsOneWidget);
    expect(find.text('70.5 kg'), findsOneWidget);
    expect(find.text('體脂：18.2 %　肌肉量：未填'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '編輯'), findsOneWidget);
    final deleteButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '刪除'),
    );
    final context = tester.element(find.byKey(const Key('body-measurement-1')));
    expect(
      deleteButton.style?.backgroundColor?.resolve({}),
      Theme.of(context).colorScheme.error,
    );
  });

  testWidgets('新增表單驗證必填體重並將資料交給 controller', (tester) async {
    final repository = _Measurements();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-body-measurement-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-body-measurement-button')));
    await tester.pump();
    expect(find.text('此欄位為必填'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('measurement-weight-field')),
      '71.25',
    );
    await tester.tap(find.byKey(const Key('save-body-measurement-button')));
    await tester.pumpAndSettle();

    expect(repository.createdWeight, 71.25);
    expect(find.text('量測紀錄已新增'), findsOneWidget);
  });
}

Widget _app(BodyMeasurementRepository repository) => ProviderScope(
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
  child: const MaterialApp(home: BodyMeasurementsPage()),
);

class _Measurements implements BodyMeasurementRepository {
  double? createdWeight;

  @override
  Future<BodyMeasurementPage> getHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? fromDate,
    DateTime? toDate,
  }) async => BodyMeasurementPage(
    items: [_measurement],
    page: 1,
    pageSize: pageSize,
    totalCount: 1,
  );

  @override
  Future<BodyMeasurement> create({
    required double weightInKilograms,
    double? bodyFatPercentage,
    double? muscleMassInKilograms,
  }) async {
    createdWeight = weightInKilograms;
    return _measurement;
  }

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
  bodyFatPercentage: 18.2,
  measuredAt: DateTime.utc(2026, 9, 3, 2),
  version: 'version-1',
);
