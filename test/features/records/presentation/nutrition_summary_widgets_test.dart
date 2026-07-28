import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/records/domain/models/nutrition_summary.dart';
import 'package:food_ledger_frontend/features/records/domain/models/weekly_nutrition_summary.dart';
import 'package:food_ledger_frontend/features/records/presentation/widgets/nutrition_summary_card.dart';
import 'package:food_ledger_frontend/features/records/presentation/widgets/weekly_nutrition_summary_card.dart';

void main() {
  testWidgets('每日摘要使用 API 翻譯名稱且缺少營養素顯示破折號', (tester) async {
    final summary = NutritionSummary.fromNutrients(
      date: DateTime(2026, 7, 28),
      timeZone: 'Asia/Taipei',
      nutrients: const [
        NutrientAmount(
          nutrientId: 1,
          code: 'Protein',
          displayName: '蛋白質',
          langCode: 'zh-TW',
          amount: 31.5,
          unitCode: 'g',
        ),
        NutrientAmount(
          nutrientId: 5,
          code: 'Iron',
          displayName: '鐵',
          langCode: 'zh-TW',
          amount: 0.04,
          unitCode: 'mg',
        ),
      ],
      mealTypes: [
        MealTypeNutritionSummary(
          mealTypeCode: 'Lunch',
          totals: [
            NutrientAmount(
              nutrientId: 1,
              code: 'Protein',
              displayName: '蛋白質',
              langCode: 'zh-TW',
              amount: 20,
              unitCode: 'g',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NutritionSummaryCard(summary: summary)),
      ),
    );

    expect(find.text('蛋白質'), findsOneWidget);
    expect(find.text('31.5 g'), findsOneWidget);
    expect(find.text('— / 2000 kcal'), findsOneWidget);
    expect(find.text('午餐'), findsOneWidget);
    expect(find.text('蛋白質 20 g'), findsOneWidget);
    expect(find.textContaining('鐵'), findsNothing);
  });

  testWidgets('每週摘要顯示七天並可切換前後週', (tester) async {
    var previousCount = 0;
    var nextCount = 0;
    final summary = WeeklyNutritionSummary(
      startDate: DateTime(2026, 7, 27),
      endDate: DateTime(2026, 8, 2),
      timeZone: 'Asia/Taipei',
      totals: const [
        NutrientAmount(
          nutrientId: 2,
          code: 'Protein',
          displayName: '蛋白質',
          langCode: 'zh-TW',
          amount: 50,
          unitCode: 'g',
        ),
        NutrientAmount(
          nutrientId: 5,
          code: 'Iron',
          displayName: '鐵',
          langCode: 'zh-TW',
          amount: 0.04,
          unitCode: 'mg',
        ),
      ],
      days: [
        for (var index = 0; index < 7; index++)
          DailyNutritionBreakdown(
            date: DateTime(2026, 7, 27 + index),
            totals: [
              NutrientAmount(
                nutrientId: 1,
                code: 'Calories',
                displayName: '熱量',
                langCode: 'zh-TW',
                amount: 100 + index.toDouble(),
                unitCode: 'kcal',
              ),
            ],
          ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyNutritionSummaryCard(
            summary: summary,
            onPreviousWeek: () => previousCount++,
            onNextWeek: () => nextCount++,
          ),
        ),
      ),
    );

    expect(find.text('07/27–08/02'), findsOneWidget);
    expect(find.text('週一'), findsOneWidget);
    expect(find.text('熱 100 kcal'), findsOneWidget);
    expect(find.text('蛋白質 50 g'), findsOneWidget);
    expect(find.textContaining('鐵'), findsNothing);

    await tester.tap(find.byKey(const Key('previous-week-button')));
    await tester.tap(find.byKey(const Key('next-week-button')));
    await tester.fling(
      find.byType(WeeklyNutritionSummaryCard),
      const Offset(500, 0),
      800,
    );
    await tester.fling(
      find.byType(WeeklyNutritionSummaryCard),
      const Offset(-500, 0),
      800,
    );
    expect(previousCount, 2);
    expect(nextCount, 2);
  });
}
