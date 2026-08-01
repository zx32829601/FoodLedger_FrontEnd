import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'iana_local_date.dart';
import 'localization_defaults.dart';

final deviceTimeZoneProvider = FutureProvider<String?>((ref) async {
  try {
    final value = (await FlutterTimezone.getLocalTimezone().timeout(
      const Duration(seconds: 2),
    )).identifier.trim();
    return value.isNotEmpty && isKnownIanaTimeZone(value) ? value : null;
  } on Object {
    return null;
  }
});

/// 管理 Nutrition API 共用 IANA 時區。
class NutritionTimeZoneController extends Notifier<String> {
  @override
  String build() => defaultNutritionTimeZone;

  void select(String timeZone) {
    final normalizedTimeZone = timeZone.trim();
    if (normalizedTimeZone.isNotEmpty) state = normalizedTimeZone;
  }

  void reset() => state = defaultNutritionTimeZone;
}

final nutritionTimeZoneProvider =
    NotifierProvider<NutritionTimeZoneController, String>(
      NutritionTimeZoneController.new,
    );

/// 管理 Food、Daily Record 與 Nutrition API 共用語系。
class NutritionLangCodeController extends Notifier<String> {
  @override
  String build() => defaultNutritionLangCode;

  void select(String langCode) {
    final normalizedLangCode = langCode.trim();
    if (normalizedLangCode.isNotEmpty) state = normalizedLangCode;
  }
}

final nutritionLangCodeProvider =
    NotifierProvider<NutritionLangCodeController, String>(
      NutritionLangCodeController.new,
    );
