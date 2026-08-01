import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/domain/models/food.dart';
import 'package:food_ledger_frontend/features/records/domain/models/nutrition_summary.dart';
import 'package:food_ledger_frontend/features/records/domain/repositories/food_repository.dart';
import 'package:food_ledger_frontend/features/records/presentation/food_detail_page.dart';
import 'package:food_ledger_frontend/features/records/presentation/providers/record_providers.dart';

void main() {
  testWidgets('輸入克數後即時換算核心與詳細營養資料', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodRepositoryProvider.overrideWithValue(_Foods())],
        child: const MaterialApp(home: FoodDetailPage(foodId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('雞胸肉'), findsOneWidget);
    expect(find.text('Chicken Breast'), findsOneWidget);
    expect(find.text('蛋白質'), findsWidgets);
    expect(find.text('31 g'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const Key('food-detail-quantity')),
      '150',
    );
    await tester.pump();

    expect(find.text('46.5 g'), findsOneWidget);
    await tester.tap(find.text('詳細營養資料（1）'));
    await tester.pumpAndSettle();
    expect(find.text('111 mg'), findsOneWidget);
  });
}

class _Foods implements FoodRepository {
  @override
  Future<Food> getFoodDetail({
    required int foodId,
    required String langCode,
  }) async => Food(
    id: 1,
    code: 'CHICKEN',
    name: '雞胸肉',
    englishName: 'Chicken Breast',
    description: '低脂蛋白質來源',
    langCode: 'zh-TW',
    categories: const [
      FoodCategory(id: 1, code: 'MEAT', displayName: '肉類', langCode: 'zh-TW'),
    ],
    nutrientsPer100Grams: const [
      NutrientAmount(
        nutrientId: 1,
        code: 'Calories',
        displayName: '熱量',
        amount: 165,
        unitCode: 'kcal',
        displayOrder: 10,
      ),
      NutrientAmount(
        nutrientId: 2,
        code: 'Protein',
        displayName: '蛋白質',
        amount: 31,
        unitCode: 'g',
        displayOrder: 20,
      ),
      NutrientAmount(
        nutrientId: 3,
        code: 'Sodium',
        displayName: '鈉',
        amount: 74,
        unitCode: 'mg',
        displayOrder: 50,
      ),
    ],
  );

  @override
  Future<FoodSearchResult> searchFoods({
    required String query,
    required String langCode,
    required int page,
    required int pageSize,
  }) => throw UnimplementedError();
}
