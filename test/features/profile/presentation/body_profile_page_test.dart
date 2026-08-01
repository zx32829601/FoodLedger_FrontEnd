import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/profile/data/mock_body_profile_repository.dart';
import 'package:food_ledger_frontend/features/authentication/domain/models/app_user.dart';
import 'package:food_ledger_frontend/features/authentication/presentation/providers/auth_providers.dart';
import 'package:food_ledger_frontend/core/localization/localization_providers.dart';
import 'package:food_ledger_frontend/features/profile/domain/models/body_profile.dart';
import 'package:food_ledger_frontend/features/profile/presentation/body_profile_page.dart';
import 'package:food_ledger_frontend/features/profile/presentation/providers/body_profile_providers.dart';

void main() {
  testWidgets('建立頁顯示完整欄位與 DefinedCode Note', (tester) async {
    await tester.pumpWidget(_testApp(MockBodyProfileRepository()));
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

  testWidgets('建立頁優先帶入裝置 IANA 時區', (tester) async {
    await tester.pumpWidget(
      _testApp(MockBodyProfileRepository(), deviceTimeZone: 'America/New_York'),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(
      find.byKey(const Key('time-zone-field')),
    );
    expect(field.controller?.text, 'America/New_York');
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
        fitnessGoalDisplayName: '舊版減脂目標',
        fitnessGoalLangCode: 'zh-TW',
        fitnessGoalNote: '這是建立資料時使用的舊目標。',
      ),
    );
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('舊版減脂目標（已停用）'), findsOneWidget);
    expect(find.text('這是建立資料時使用的舊目標。'), findsOneWidget);
    expect(find.text('目前儲存的代碼已停用，請改選一個可用選項。'), findsOneWidget);
  });

  testWidgets('身高超過兩位小數時顯示欄位錯誤', (tester) async {
    await tester.pumpWidget(_testApp(MockBodyProfileRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('height-field')), '175.555');
    final saveButton = find.byKey(const Key('save-body-profile-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('身高最多可輸入兩位小數'), findsOneWidget);
  });

  testWidgets('無效時區仍可開啟日期選擇器並使用預設 IANA 日期', (tester) async {
    await tester.pumpWidget(_testApp(MockBodyProfileRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('time-zone-field')),
      'Invalid/Zone',
    );
    await tester.tap(find.byKey(const Key('birth-date-field')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('閏日的十八歲界線會夾到二月最後一天', (tester) async {
    final repository = MockBodyProfileRepository(
      profile: BodyProfile(
        birthDate: DateTime(2010, 3),
        biologicalSexCode: 'MALE',
        heightInCentimeters: 175,
        fitnessGoalCode: 'MAINTAIN',
        activityLevelCode: 'MODERATE',
        timeZone: 'UTC',
        version: 'leap-version',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        repository,
        now: DateTime.utc(2028, 2, 29, 12),
        deviceTimeZone: 'UTC',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('birth-date-field')));
    await tester.pumpAndSettle();
    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );

    expect(dialog.lastDate, DateTime(2010, 2, 28));
    expect(dialog.initialDate, DateTime(2010, 2, 28));
  });

  testWidgets('最早可選生日包含尚未滿 121 歲的前一天', (tester) async {
    final repository = MockBodyProfileRepository(
      profile: BodyProfile(
        birthDate: DateTime(1905, 8, 2),
        biologicalSexCode: 'MALE',
        heightInCentimeters: 175,
        fitnessGoalCode: 'MAINTAIN',
        activityLevelCode: 'MODERATE',
        timeZone: 'Asia/Taipei',
        version: 'oldest-version',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        repository,
        now: DateTime.utc(2026, 8, 1, 4),
        deviceTimeZone: 'Asia/Taipei',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('birth-date-field')));
    await tester.pumpAndSettle();
    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );

    expect(dialog.firstDate, DateTime(1905, 8, 2));
    expect(dialog.initialDate, DateTime(1905, 8, 2));
  });

  testWidgets('修改時區後會以新時區重新驗證十八歲生日', (tester) async {
    final repository = MockBodyProfileRepository(
      profile: BodyProfile(
        birthDate: DateTime(2008, 3, 8),
        biologicalSexCode: 'MALE',
        heightInCentimeters: 175,
        fitnessGoalCode: 'MAINTAIN',
        activityLevelCode: 'MODERATE',
        timeZone: 'Asia/Taipei',
        version: 'timezone-version',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        repository,
        now: DateTime.utc(2026, 3, 8, 4, 30),
        deviceTimeZone: 'Asia/Taipei',
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('time-zone-field')),
      'America/New_York',
    );
    final saveButton = find.byKey(const Key('save-body-profile-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('年齡必須介於 18 到 120 歲'), findsOneWidget);
  });
}

const _authenticatedUser = AppUser(
  id: 'profile-user',
  userAccount: 'profile_user',
  displayName: 'Profile User',
  email: 'profile@example.com',
  isAdmin: false,
);

Widget _testApp(
  MockBodyProfileRepository repository, {
  String? deviceTimeZone,
  DateTime? now,
}) => ProviderScope(
  overrides: [
    initialAuthUserProvider.overrideWithValue(_authenticatedUser),
    restoreSessionOnStartProvider.overrideWithValue(false),
    bodyProfileRepositoryProvider.overrideWithValue(repository),
    deviceTimeZoneProvider.overrideWith((ref) async => deviceTimeZone),
    if (now != null) bodyProfileClockProvider.overrideWithValue(() => now),
  ],
  child: const MaterialApp(home: BodyProfilePage()),
);
