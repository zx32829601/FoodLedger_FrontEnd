import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/data/mock_foods.dart';
import 'package:food_ledger_frontend/features/records/domain/models/daily_record.dart';
import 'package:food_ledger_frontend/features/records/domain/models/meal_type_option.dart';
import 'package:food_ledger_frontend/features/records/domain/repositories/defined_code_repository.dart';
import 'package:food_ledger_frontend/features/records/presentation/providers/record_providers.dart';
import 'package:food_ledger_frontend/features/records/presentation/widgets/add_record_dialog.dart';

void main() {
  testWidgets('編輯紀錄切換餐別時不改變既有食用時間', (tester) async {
    final record = DailyRecord(
      id: 1,
      food: mockFoods.first,
      quantityGrams: 100,
      consumedAt: DateTime.utc(2026, 7, 28, 15, 15),
      mealTypeCode: 'Dinner',
      nutrients: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          definedCodeRepositoryProvider.overrideWithValue(_MealTypes()),
        ],
        child: MaterialApp(
          home: Scaffold(body: AddRecordDialog(initialRecord: record)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final timeButton = find.byKey(const Key('record-time-field'));
    final before = tester
        .widgetList<Text>(
          find.descendant(of: timeButton, matching: find.byType(Text)),
        )
        .single
        .data;

    await tester.tap(find.byKey(const Key('record-meal-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('早餐').last);
    await tester.pumpAndSettle();

    final after = tester
        .widgetList<Text>(
          find.descendant(of: timeButton, matching: find.byType(Text)),
        )
        .single
        .data;
    expect(after, before);
    expect(find.text('早餐'), findsOneWidget);
  });
}

class _MealTypes implements DefinedCodeRepository {
  @override
  Future<List<MealTypeOption>> getMealTypes({required String langCode}) async =>
      const [
        MealTypeOption(code: 'Breakfast', displayName: '早餐', sortOrder: 1),
        MealTypeOption(code: 'Dinner', displayName: '晚餐', sortOrder: 2),
      ];
}
