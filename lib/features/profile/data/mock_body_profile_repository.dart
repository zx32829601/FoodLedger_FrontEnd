import '../domain/models/body_profile.dart';
import '../domain/models/body_profile_option.dart';
import '../domain/repositories/body_profile_repository.dart';

/// 提供 Prototype 與 Widget Test 使用的可預測身體資料。
class MockBodyProfileRepository implements BodyProfileRepository {
  MockBodyProfileRepository({this.profile});

  BodyProfile? profile;

  @override
  Future<BodyProfile?> getProfile({
    required String langCode,
    Future<void>? cancelWhen,
  }) async => profile;

  @override
  Future<BodyProfile> saveProfile(
    BodyProfile profile, {
    Future<void>? cancelWhen,
  }) async {
    this.profile = BodyProfile(
      birthDate: profile.birthDate,
      biologicalSexCode: profile.biologicalSexCode,
      heightInCentimeters: profile.heightInCentimeters,
      fitnessGoalCode: profile.fitnessGoalCode,
      activityLevelCode: profile.activityLevelCode,
      timeZone: profile.timeZone,
      version: 'mock-version',
    );
    return this.profile!;
  }

  @override
  Future<List<BodyProfileOption>> getFitnessGoals({
    required String langCode,
  }) async => const [
    BodyProfileOption(
      code: 'MAINTAIN',
      displayName: '維持體重',
      sortOrder: 1,
      langCode: 'zh-TW',
      note: '維持目前熱量平衡。',
    ),
  ];

  @override
  Future<List<BodyProfileOption>> getActivityLevels({
    required String langCode,
  }) async => const [
    BodyProfileOption(
      code: 'MODERATE',
      displayName: '中度活動',
      sortOrder: 1,
      langCode: 'zh-TW',
      note: '每週有三到五天的中等強度活動。',
    ),
  ];
}
