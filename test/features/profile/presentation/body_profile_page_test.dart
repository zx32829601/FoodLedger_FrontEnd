import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/profile/data/mock_body_profile_repository.dart';
import 'package:food_ledger_frontend/features/profile/domain/models/body_profile.dart';
import 'package:food_ledger_frontend/features/profile/presentation/body_profile_page.dart';
import 'package:food_ledger_frontend/features/profile/presentation/providers/body_profile_providers.dart';

void main() {
  testWidgets('建立頁顯示完整欄位與 DefinedCode Note', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bodyProfileRepositoryProvider.overrideWithValue(
            MockBodyProfileRepository(),
          ),
        ],
        child: const MaterialApp(home: BodyProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('birth-date-field')), findsOneWidget);
    expect(find.byKey(const Key('biological-sex-field')), findsOneWidget);
    expect(find.byKey(const Key('height-field')), findsOneWidget);
    expect(find.byKey(const Key('fitness-goal-field')), findsOneWidget);
    expect(find.byKey(const Key('activity-level-field')), findsOneWidget);
    expect(find.byKey(const Key('time-zone-field')), findsOneWidget);
    expect(find.text('維持目前熱量平衡。'), findsOneWidget);
    expect(find.text('每週有三到五天的中等強度活動。'), findsOneWidget);
  });

  testWidgets('建立頁預先帶入應用程式 IANA 時區', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bodyProfileRepositoryProvider.overrideWithValue(
            MockBodyProfileRepository(),
          ),
        ],
        child: const MaterialApp(home: BodyProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(
      find.byKey(const Key('time-zone-field')),
    );
    expect(field.controller?.text, 'Asia/Taipei');
  });

  testWidgets('已停用的現有代碼仍可讀取並要求重新選擇', (tester) async {
    final repository = MockBodyProfileRepository(
      profile: BodyProfile(
        birthDate: DateTime(1990, 5, 20),
        biologicalSexCode: 'MALE',
        heightInCentimeters: 175,
        fitnessGoalCode: 'RETIRED_GOAL',
        activityLevelCode: 'MODERATE',
        timeZone: 'Asia/Taipei',
        version: 'version-1',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bodyProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: BodyProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RETIRED_GOAL（已停用）'), findsOneWidget);
    expect(find.text('目前儲存的代碼已停用，請改選一個可用選項。'), findsOneWidget);
  });
}
