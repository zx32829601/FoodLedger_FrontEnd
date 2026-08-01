import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/localization/localization_providers.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/api_body_profile_repository.dart';
import '../../domain/models/body_profile.dart';
import '../../domain/models/body_profile_option.dart';
import '../../domain/repositories/body_profile_repository.dart';

final bodyProfileRepositoryProvider = Provider<BodyProfileRepository>((ref) {
  return ApiBodyProfileRepository(ref.watch(apiClientProvider).dio);
});

class BodyProfileController extends AsyncNotifier<BodyProfile?> {
  @override
  Future<BodyProfile?> build() async {
    final profile = await ref.watch(bodyProfileRepositoryProvider).getProfile();
    if (profile != null) {
      ref.read(nutritionTimeZoneProvider.notifier).select(profile.timeZone);
    }
    return profile;
  }

  Future<BodyProfile> save(BodyProfile profile) async {
    state = const AsyncLoading();
    try {
      final saved = await ref
          .read(bodyProfileRepositoryProvider)
          .saveProfile(profile);
      ref.read(nutritionTimeZoneProvider.notifier).select(saved.timeZone);
      state = AsyncData(saved);
      return saved;
    } on ApiException catch (error, stackTrace) {
      if (error.code == 'BodyProfile.Conflict') {
        state = await AsyncValue.guard(
          ref.read(bodyProfileRepositoryProvider).getProfile,
        );
      } else {
        state = AsyncError(error, stackTrace);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(bodyProfileRepositoryProvider).getProfile,
    );
  }
}

final bodyProfileProvider =
    AsyncNotifierProvider<BodyProfileController, BodyProfile?>(
      BodyProfileController.new,
    );

final bodyProfileOptionsProvider = FutureProvider<BodyProfileOptions>((
  ref,
) async {
  final repository = ref.watch(bodyProfileRepositoryProvider);
  final langCode = ref.watch(nutritionLangCodeProvider);
  final results = await Future.wait([
    repository.getFitnessGoals(langCode: langCode),
    repository.getActivityLevels(langCode: langCode),
  ]);
  return (fitnessGoals: results[0], activityLevels: results[1]);
});
