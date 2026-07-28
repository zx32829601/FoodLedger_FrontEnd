import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/admin/domain/admin_food.dart';
import 'package:food_ledger_frontend/features/admin/domain/admin_food_repository.dart';
import 'package:food_ledger_frontend/features/admin/domain/nutrient_definition.dart';
import 'package:food_ledger_frontend/features/admin/presentation/admin_page.dart';
import 'package:food_ledger_frontend/features/records/data/mock_food_repository.dart';

void main() {
  testWidgets('建立食物表單使用 LangCode 翻譯後的營養素名稱', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminFoodRepositoryProvider.overrideWithValue(
            _FakeAdminFoodRepository(),
          ),
          adminFoodSearchRepositoryProvider.overrideWithValue(
            MockFoodRepository(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminPage())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-food-button')));
    await tester.pumpAndSettle();

    expect(find.text('蛋白質（g／每 100 克）'), findsOneWidget);
    expect(find.text('Protein（g／每 100 克）'), findsNothing);
  });

  testWidgets('建立食物只送出有填寫的營養素，不把缺少資料當成零', (tester) async {
    final repository = _FakeAdminFoodRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminFoodRepositoryProvider.overrideWithValue(repository),
          adminFoodSearchRepositoryProvider.overrideWithValue(
            MockFoodRepository(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminPage())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-food-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('food-code-field')),
      'TEST_FOOD',
    );
    await tester.enterText(find.byKey(const Key('food-name-field')), '測試食物');
    await tester.enterText(find.byKey(const Key('nutrient-Protein')), '12.5');
    await tester.tap(find.byKey(const Key('save-food-button')));
    await tester.pumpAndSettle();

    expect(repository.savedNutrients, {'Protein': 12.5});
    expect(repository.savedTranslations?['zh-TW']?.displayName, '測試食物');
  });
}

class _FakeAdminFoodRepository implements AdminFoodRepository {
  Map<String, double>? savedNutrients;
  Map<String, AdminFoodTranslation>? savedTranslations;

  @override
  Future<List<NutrientDefinition>> getNutrients({
    required String langCode,
  }) async {
    return const [
      NutrientDefinition(
        nutrientId: 1,
        code: 'Protein',
        displayName: '蛋白質',
        langCode: 'zh-TW',
        unitCode: 'g',
      ),
      NutrientDefinition(
        nutrientId: 2,
        code: 'Sodium',
        displayName: '鈉',
        langCode: 'zh-TW',
        unitCode: 'mg',
      ),
    ];
  }

  @override
  Future<AdminFood> get(int foodId) => throw UnimplementedError();

  @override
  Future<AdminFood> save({
    int? foodId,
    required String foodCode,
    required Map<String, AdminFoodTranslation> translations,
    required Map<String, double> nutrients,
  }) async {
    savedNutrients = Map.of(nutrients);
    savedTranslations = Map.of(translations);
    return AdminFood(
      id: foodId ?? 1,
      code: foodCode,
      translations: translations,
      nutrients: nutrients,
    );
  }

  @override
  Future<void> delete(int foodId) => throw UnimplementedError();
}
