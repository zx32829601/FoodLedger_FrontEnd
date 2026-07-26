import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme/theme_mode_controller.dart';
import 'app/theme/theme_preference_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themePreferenceStore = SharedPreferencesThemePreferenceStore();
  final initialThemeMode = await themePreferenceStore.load();

  runApp(
    ProviderScope(
      overrides: [
        themePreferenceStoreProvider.overrideWithValue(themePreferenceStore),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
      ],
      child: const FoodLedgerApp(),
    ),
  );
}
