import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/app/theme/theme_mode_controller.dart';
import 'package:food_ledger_frontend/app/theme/theme_preference_store.dart';

void main() {
  group('ThemeModeController', () {
    test('切換深色模式時會更新狀態並保存使用者偏好', () async {
      // 準備
      final store = _FakeThemePreferenceStore();
      final container = ProviderContainer(
        overrides: [
          themePreferenceStoreProvider.overrideWithValue(store),
          initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        ],
      );
      addTearDown(container.dispose);

      // 執行
      await container
          .read(themeModeProvider.notifier)
          .setDarkMode(enabled: true);

      // 驗證
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(store.savedMode, ThemeMode.dark);
    });

    test('建立 Controller 時會使用啟動階段載入的深色偏好', () {
      // 準備
      final container = ProviderContainer(
        overrides: [initialThemeModeProvider.overrideWithValue(ThemeMode.dark)],
      );
      addTearDown(container.dispose);

      // 執行
      final mode = container.read(themeModeProvider);

      // 驗證
      expect(mode, ThemeMode.dark);
    });
  });
}

class _FakeThemePreferenceStore implements ThemePreferenceStore {
  ThemeMode? savedMode;

  @override
  Future<ThemeMode> load() async => ThemeMode.light;

  @override
  Future<void> save(ThemeMode mode) async {
    savedMode = mode;
  }
}
