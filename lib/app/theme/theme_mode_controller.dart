import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_preference_store.dart';

/// 啟動階段已從平台偏好儲存載入的主題，避免畫面先以錯誤主題閃爍。
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);

/// 管理目前應用程式使用的亮色或暗色模式。
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> setDarkMode({required bool enabled}) async {
    state = enabled ? ThemeMode.dark : ThemeMode.light;
    await ref.read(themePreferenceStoreProvider).save(state);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
