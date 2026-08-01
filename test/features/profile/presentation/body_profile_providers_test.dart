import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/api/api_exception.dart';
import 'package:food_ledger_frontend/core/localization/localization_providers.dart';
import 'package:food_ledger_frontend/features/authentication/data/mock_auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/domain/models/app_user.dart';
import 'package:food_ledger_frontend/features/authentication/presentation/providers/auth_providers.dart';
import 'package:food_ledger_frontend/features/profile/domain/models/body_profile.dart';
import 'package:food_ledger_frontend/features/profile/domain/models/body_profile_option.dart';
import 'package:food_ledger_frontend/features/profile/domain/repositories/body_profile_repository.dart';
import 'package:food_ledger_frontend/features/profile/presentation/providers/body_profile_providers.dart';

void main() {
  test('載入已有資料後同步共用時區', () async {
    final repository = _RecordingRepository(
      profile: _profile(timeZone: 'America/New_York'),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(bodyProfileProvider.future);

    expect(container.read(nutritionTimeZoneProvider), 'America/New_York');
  });

  test('儲存成功後同步共用時區並保留新版本', () async {
    final repository = _RecordingRepository();
    final container = _container(repository);
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
    final container = _container(repository);
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
    final container = _container(repository);
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

  test('登出後清除前一位使用者資料並為新使用者重載', () async {
    final repository = _QueuedRepository([
      _profile(version: 'user-a', timeZone: 'America/New_York'),
      _profile(version: 'user-b', timeZone: 'Asia/Tokyo'),
    ]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(bodyProfileProvider, (_, _) {});
    addTearDown(subscription.close);

    expect(
      (await container.read(bodyProfileProvider.future))?.version,
      'user-a',
    );
    expect(container.read(nutritionTimeZoneProvider), 'America/New_York');

    await container.read(authenticationProvider.notifier).signOut();
    expect(await container.read(bodyProfileProvider.future), isNull);
    expect(container.read(nutritionTimeZoneProvider), 'Asia/Taipei');

    await container
        .read(authenticationProvider.notifier)
        .signIn(loginId: 'user_b@example.com', password: 'Password1');
    expect(
      (await container.read(bodyProfileProvider.future))?.version,
      'user-b',
    );
    expect(container.read(nutritionTimeZoneProvider), 'Asia/Tokyo');
    expect(repository.getCount, 2);
  });

  test('舊帳號延遲儲存完成時不會覆寫新帳號資料與時區', () async {
    final repository = _DelayedSaveRepository([
      _profile(version: 'user-a', timeZone: 'America/New_York'),
      _profile(version: 'user-b', timeZone: 'Asia/Tokyo'),
    ]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(bodyProfileProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(bodyProfileProvider.future);

    final staleSave = container
        .read(bodyProfileProvider.notifier)
        .save(_profile(version: 'late-user-a', timeZone: 'America/Chicago'));
    await repository.saveStarted.future;
    await container.read(authenticationProvider.notifier).signOut();
    expect(await container.read(bodyProfileProvider.future), isNull);
    await container
        .read(authenticationProvider.notifier)
        .signIn(loginId: 'user_b@example.com', password: 'Password1');
    expect(
      (await container.read(bodyProfileProvider.future))?.version,
      'user-b',
    );

    repository.completeSave(
      _profile(version: 'late-user-a', timeZone: 'America/Chicago'),
    );
    await expectLater(
      staleSave,
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'Auth.SessionChanged',
        ),
      ),
    );

    expect(container.read(bodyProfileProvider).value?.version, 'user-b');
    expect(container.read(nutritionTimeZoneProvider), 'Asia/Tokyo');
  });

  test('舊帳號 conflict 延遲刷新不會覆寫新帳號資料', () async {
    final repository = _DelayedConflictRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(bodyProfileProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(bodyProfileProvider.future);

    final staleSave = container
        .read(bodyProfileProvider.notifier)
        .save(_profile(version: 'stale-user-a'));
    await repository.refreshStarted.future;
    await container.read(authenticationProvider.notifier).signOut();
    expect(await container.read(bodyProfileProvider.future), isNull);
    await container
        .read(authenticationProvider.notifier)
        .signIn(loginId: 'user_b@example.com', password: 'Password1');
    expect(
      (await container.read(bodyProfileProvider.future))?.version,
      'user-b',
    );

    repository.completeRefresh(
      _profile(version: 'late-user-a', timeZone: 'America/Chicago'),
    );
    await expectLater(
      staleSave,
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'Auth.SessionChanged',
        ),
      ),
    );

    expect(container.read(bodyProfileProvider).value?.version, 'user-b');
    expect(container.read(nutritionTimeZoneProvider), 'Asia/Tokyo');
  });
}

const _userA = AppUser(
  id: 'user-a',
  userAccount: 'user_a',
  displayName: '使用者 A',
  email: 'user_a@example.com',
  isAdmin: false,
);

ProviderContainer _container(BodyProfileRepository repository) =>
    ProviderContainer(
      overrides: [
        initialAuthUserProvider.overrideWithValue(_userA),
        restoreSessionOnStartProvider.overrideWithValue(false),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        bodyProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );

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
  Future<BodyProfile?> getProfile({
    required String langCode,
    Future<void>? cancelWhen,
  }) async {
    getCount++;
    return profile;
  }

  @override
  Future<BodyProfile> saveProfile(
    BodyProfile value, {
    Future<void>? cancelWhen,
  }) async {
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

class _QueuedRepository implements BodyProfileRepository {
  _QueuedRepository(this.profiles);

  final List<BodyProfile> profiles;
  int getCount = 0;

  @override
  Future<BodyProfile?> getProfile({
    required String langCode,
    Future<void>? cancelWhen,
  }) async => profiles[getCount++];

  @override
  Future<BodyProfile> saveProfile(
    BodyProfile profile, {
    Future<void>? cancelWhen,
  }) async => profile;

  @override
  Future<List<BodyProfileOption>> getActivityLevels({
    required String langCode,
  }) async => const [];

  @override
  Future<List<BodyProfileOption>> getFitnessGoals({
    required String langCode,
  }) async => const [];
}

class _DelayedSaveRepository implements BodyProfileRepository {
  _DelayedSaveRepository(this.profiles);

  final List<BodyProfile> profiles;
  final saveStarted = Completer<void>();
  final _saveResult = Completer<BodyProfile>();
  int _getCount = 0;

  void completeSave(BodyProfile profile) => _saveResult.complete(profile);

  @override
  Future<BodyProfile?> getProfile({
    required String langCode,
    Future<void>? cancelWhen,
  }) async => profiles[_getCount++];

  @override
  Future<BodyProfile> saveProfile(
    BodyProfile profile, {
    Future<void>? cancelWhen,
  }) {
    if (!saveStarted.isCompleted) saveStarted.complete();
    return _saveResult.future;
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

class _DelayedConflictRepository implements BodyProfileRepository {
  final refreshStarted = Completer<void>();
  final _refreshResult = Completer<BodyProfile?>();
  int _getCount = 0;

  void completeRefresh(BodyProfile profile) => _refreshResult.complete(profile);

  @override
  Future<BodyProfile?> getProfile({
    required String langCode,
    Future<void>? cancelWhen,
  }) {
    final call = _getCount++;
    if (call == 0) {
      return Future.value(
        _profile(version: 'user-a', timeZone: 'America/New_York'),
      );
    }
    if (call == 1) {
      refreshStarted.complete();
      return _refreshResult.future;
    }
    return Future.value(_profile(version: 'user-b', timeZone: 'Asia/Tokyo'));
  }

  @override
  Future<BodyProfile> saveProfile(
    BodyProfile profile, {
    Future<void>? cancelWhen,
  }) => throw const ApiException(
    message: '資料已更新',
    code: 'BodyProfile.Conflict',
    statusCode: 409,
  );

  @override
  Future<List<BodyProfileOption>> getActivityLevels({
    required String langCode,
  }) async => const [];

  @override
  Future<List<BodyProfileOption>> getFitnessGoals({
    required String langCode,
  }) async => const [];
}
