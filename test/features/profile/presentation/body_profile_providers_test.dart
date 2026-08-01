import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/api/api_exception.dart';
import 'package:food_ledger_frontend/core/localization/localization_providers.dart';
import 'package:food_ledger_frontend/features/profile/domain/models/body_profile.dart';
import 'package:food_ledger_frontend/features/profile/domain/models/body_profile_option.dart';
import 'package:food_ledger_frontend/features/profile/domain/repositories/body_profile_repository.dart';
import 'package:food_ledger_frontend/features/profile/presentation/providers/body_profile_providers.dart';

void main() {
  test('載入已有資料後同步共用時區', () async {
    final repository = _RecordingRepository(
      profile: _profile(timeZone: 'America/New_York'),
    );
    final container = ProviderContainer(
      overrides: [bodyProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(bodyProfileProvider.future);

    expect(container.read(nutritionTimeZoneProvider), 'America/New_York');
  });

  test('儲存成功後同步共用時區並保留新版本', () async {
    final repository = _RecordingRepository();
    final container = ProviderContainer(
      overrides: [bodyProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(bodyProfileProvider.future);

    final saved = await container
        .read(bodyProfileProvider.notifier)
        .save(_profile(timeZone: 'America/New_York'));

    expect(saved.version, 'saved-version');
    expect(container.read(nutritionTimeZoneProvider), 'America/New_York');
  });

  test('遇到過期版本時重新讀取最新資料並保留 conflict', () async {
    final latest = _profile(version: 'latest-version');
    final repository = _RecordingRepository(
      profile: latest,
      saveError: const ApiException(
        message: '資料已更新',
        code: 'BodyProfile.Conflict',
        statusCode: 409,
      ),
    );
    final container = ProviderContainer(
      overrides: [bodyProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(bodyProfileProvider.future);

    expect(
      () => container
          .read(bodyProfileProvider.notifier)
          .save(_profile(version: 'stale-version')),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'BodyProfile.Conflict',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(bodyProfileProvider).value?.version,
      'latest-version',
    );
    expect(repository.getCount, 2);
  });

  test('一般儲存失敗時保留原資料與表單狀態', () async {
    final original = _profile(version: 'original-version');
    final repository = _RecordingRepository(
      profile: original,
      saveError: const ApiException(
        message: '輸入資料不正確',
        code: 'Validation.Failed',
        statusCode: 400,
      ),
    );
    final container = ProviderContainer(
      overrides: [bodyProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(bodyProfileProvider.future);

    await expectLater(
      container
          .read(bodyProfileProvider.notifier)
          .save(_profile(version: 'original-version')),
      throwsA(isA<ApiException>()),
    );

    expect(container.read(bodyProfileProvider).value, same(original));
  });
}

BodyProfile _profile({String? version, String timeZone = 'Asia/Taipei'}) =>
    BodyProfile(
      birthDate: DateTime(1990, 5, 20),
      biologicalSexCode: 'MALE',
      heightInCentimeters: 175,
      fitnessGoalCode: 'MAINTAIN',
      activityLevelCode: 'MODERATE',
      timeZone: timeZone,
      version: version,
    );

class _RecordingRepository implements BodyProfileRepository {
  _RecordingRepository({this.profile, this.saveError});

  BodyProfile? profile;
  final ApiException? saveError;
  int getCount = 0;

  @override
  Future<BodyProfile?> getProfile() async {
    getCount++;
    return profile;
  }

  @override
  Future<BodyProfile> saveProfile(BodyProfile value) async {
    if (saveError case final error?) throw error;
    profile = BodyProfile(
      birthDate: value.birthDate,
      biologicalSexCode: value.biologicalSexCode,
      heightInCentimeters: value.heightInCentimeters,
      fitnessGoalCode: value.fitnessGoalCode,
      activityLevelCode: value.activityLevelCode,
      timeZone: value.timeZone,
      version: 'saved-version',
    );
    return profile!;
  }

  @override
  Future<List<BodyProfileOption>> getActivityLevels({
    required String langCode,
  }) async => const [];

  @override
  Future<List<BodyProfileOption>> getFitnessGoals({
    required String langCode,
  }) async => const [];
}
