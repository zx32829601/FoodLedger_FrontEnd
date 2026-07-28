import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/localization/localization_providers.dart';

void main() {
  test('NutritionLangCodeController 正規化有效值並忽略空白', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(nutritionLangCodeProvider.notifier).select(' en-US ');
    expect(container.read(nutritionLangCodeProvider), 'en-US');

    container.read(nutritionLangCodeProvider.notifier).select('   ');
    expect(container.read(nutritionLangCodeProvider), 'en-US');
  });

  test('NutritionTimeZoneController 正規化有效值並忽略空白', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(nutritionTimeZoneProvider.notifier)
        .select(' America/New_York ');
    expect(container.read(nutritionTimeZoneProvider), 'America/New_York');

    container.read(nutritionTimeZoneProvider.notifier).select('');
    expect(container.read(nutritionTimeZoneProvider), 'America/New_York');
  });
}
