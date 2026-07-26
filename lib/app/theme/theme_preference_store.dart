import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 保存不具敏感性的顯示主題偏好。
abstract interface class ThemePreferenceStore {
  /// 載入使用者上次選擇的主題；沒有偏好時使用亮色模式。
  Future<ThemeMode> load();

  /// 保存使用者選擇的亮色或深色模式。
  Future<void> save(ThemeMode mode);
}

/// 使用跨平台 Shared Preferences 保存主題偏好。
class SharedPreferencesThemePreferenceStore implements ThemePreferenceStore {
  SharedPreferencesThemePreferenceStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _themeModeKey = 'appearance.theme_mode';
  static const _darkModeValue = 'dark';
  static const _lightModeValue = 'light';

  final SharedPreferencesAsync _preferences;

  @override
  Future<ThemeMode> load() async {
    final savedValue = await _preferences.getString(_themeModeKey);
    return savedValue == _darkModeValue ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Future<void> save(ThemeMode mode) {
    final value = mode == ThemeMode.dark ? _darkModeValue : _lightModeValue;
    return _preferences.setString(_themeModeKey, value);
  }
}

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>((ref) {
  return SharedPreferencesThemePreferenceStore();
});
