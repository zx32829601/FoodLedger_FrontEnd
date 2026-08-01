import '../models/body_profile.dart';
import '../models/body_profile_option.dart';

abstract interface class BodyProfileRepository {
  Future<BodyProfile?> getProfile({
    required String langCode,
    Future<void>? cancelWhen,
  });

  Future<BodyProfile> saveProfile(
    BodyProfile profile, {
    Future<void>? cancelWhen,
  });

  Future<List<BodyProfileOption>> getFitnessGoals({required String langCode});

  Future<List<BodyProfileOption>> getActivityLevels({required String langCode});
}
