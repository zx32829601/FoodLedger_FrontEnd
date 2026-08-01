import 'dart:async';

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

final bodyProfileClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

class BodyProfileController extends AsyncNotifier<BodyProfile?> {
  Completer<void>? _sessionChanged;
  String? _activeUserId;
  bool _hasSession = false;
  bool _disposeRegistered = false;

  @override
  Future<BodyProfile?> build() async {
    final userId = ref.watch(
      authenticationProvider.select((state) => state.user?.id),
    );
    _activateSession(userId);
    if (userId == null) {
      await Future<void>.value();
      ref.read(nutritionTimeZoneProvider.notifier).reset();
      return null;
    }

    final langCode = ref.watch(nutritionLangCodeProvider);
    final profile = await ref
        .watch(bodyProfileRepositoryProvider)
        .getProfile(langCode: langCode, cancelWhen: _cancelWhen);
    _ensureCurrentSession(userId);
    if (profile != null) {
      ref.read(nutritionTimeZoneProvider.notifier).select(profile.timeZone);
    }
    return profile;
  }

  Future<BodyProfile> save(BodyProfile profile) async {
    final userId = _currentUserId();
    final cancelWhen = _cancelWhen;
    try {
      final saved = await ref
          .read(bodyProfileRepositoryProvider)
          .saveProfile(profile, cancelWhen: cancelWhen);
      _ensureCurrentSession(userId);
      ref.read(nutritionTimeZoneProvider.notifier).select(saved.timeZone);
      state = AsyncData(saved);
      return saved;
    } on ApiException catch (error, stackTrace) {
      _ensureCurrentSession(userId);
      if (error.code == 'BodyProfile.Conflict') {
        final langCode = ref.read(nutritionLangCodeProvider);
        final refreshed = await AsyncValue.guard(
          () => ref
              .read(bodyProfileRepositoryProvider)
              .getProfile(langCode: langCode, cancelWhen: cancelWhen),
        );
        _ensureCurrentSession(userId);
        state = refreshed;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reload() async {
    final userId = _currentUserId();
    final cancelWhen = _cancelWhen;
    state = const AsyncLoading();
    final langCode = ref.read(nutritionLangCodeProvider);
    try {
      final profile = await ref
          .read(bodyProfileRepositoryProvider)
          .getProfile(langCode: langCode, cancelWhen: cancelWhen);
      _ensureCurrentSession(userId);
      state = AsyncData(profile);
    } catch (error, stackTrace) {
      if (_isCurrentSession(userId)) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> get _cancelWhen => _sessionChanged!.future;

  void _activateSession(String? userId) {
    if (_hasSession && _activeUserId == userId) return;
    if (!(_sessionChanged?.isCompleted ?? true)) {
      _sessionChanged!.complete();
    }
    _activeUserId = userId;
    _sessionChanged = Completer<void>();
    _hasSession = true;
    if (!_disposeRegistered) {
      ref.onDispose(() {
        if (!(_sessionChanged?.isCompleted ?? true)) {
          _sessionChanged!.complete();
        }
      });
      _disposeRegistered = true;
    }
  }

  String _currentUserId() {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null || !_isCurrentSession(userId)) {
      throw _sessionChangedError;
    }
    return userId;
  }

  bool _isCurrentSession(String userId) =>
      _activeUserId == userId &&
      ref.read(authenticationProvider).user?.id == userId;

  void _ensureCurrentSession(String userId) {
    if (!_isCurrentSession(userId)) throw _sessionChangedError;
  }

  static const _sessionChangedError = ApiException(
    message: '登入使用者已變更，已取消原本的操作。',
    code: 'Auth.SessionChanged',
    statusCode: 401,
  );
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
