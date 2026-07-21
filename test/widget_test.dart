import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/app/app.dart';
import 'package:food_ledger_frontend/features/authentication/domain/models/app_user.dart';
import 'package:food_ledger_frontend/features/authentication/presentation/providers/auth_providers.dart';

void main() {
  const memberUser = AppUser(
    id: 'member-1',
    displayName: '測試會員',
    email: 'member@example.com',
    isAdmin: false,
  );
  const adminUser = AppUser(
    id: 'admin-1',
    displayName: '測試管理員',
    email: 'admin@example.com',
    isAdmin: true,
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    required Size surfaceSize,
    AppUser? initialUser = memberUser,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialAuthUserProvider.overrideWithValue(initialUser)],
        child: const FoodLedgerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('未登入使用者會導向登入頁', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);

    expect(find.text('歡迎回來'), findsOneWidget);
    expect(find.byKey(const Key('auth-email-field')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('登入欄位在輸入時不顯示錯誤，失去焦點後才驗證', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);

    await tester.enterText(find.byKey(const Key('auth-email-field')), 'member');
    await tester.pump();

    expect(find.text('請輸入有效的電子郵件'), findsNothing);

    await tester.tap(find.byKey(const Key('auth-password-field')));
    await tester.pump();

    expect(find.text('請輸入有效的電子郵件'), findsOneWidget);
  });

  testWidgets('點擊登入時會檢查整張表單', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);

    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pump();

    expect(find.text('請輸入有效的電子郵件'), findsOneWidget);
    expect(find.text('密碼至少需要 8 個字元'), findsOneWidget);
  });

  testWidgets('密碼出現錯誤後會在輸入達 8 個字元時立即清除', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);

    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pump();
    expect(find.text('密碼至少需要 8 個字元'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      List.filled(7, 'x').join(),
    );
    await tester.pump();
    expect(find.text('密碼至少需要 8 個字元'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      List.filled(8, 'x').join(),
    );
    await tester.pump();
    expect(find.text('密碼至少需要 8 個字元'), findsNothing);
  });

  testWidgets('使用者可以登入並進入首頁', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);
    final validPassword = List.filled(8, 'x').join();

    await tester.enterText(
      find.byKey(const Key('auth-email-field')),
      'member@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      validPassword,
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('今天吃得怎麼樣？'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('使用者可以註冊並直接進入首頁', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);
    final validPassword = List.filled(8, 'x').join();

    await tester.tap(find.byKey(const Key('switch-auth-mode-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('display-name-field')), '新會員');
    await tester.enterText(
      find.byKey(const Key('auth-email-field')),
      'new.member@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      validPassword,
    );
    await tester.enterText(
      find.byKey(const Key('confirm-password-field')),
      validPassword,
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('今天吃得怎麼樣？'), findsOneWidget);
  });

  testWidgets('手機寬度顯示底部導覽並可切換到紀錄頁', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('今天吃得怎麼樣？'), findsOneWidget);
    expect(find.text('今日飲食'), findsOneWidget);

    final recordsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('紀錄'),
    );
    await tester.tap(recordsDestination);
    await tester.pumpAndSettle();

    expect(find.text('飲食紀錄'), findsOneWidget);
  });

  testWidgets('飲食紀錄可以開啟日曆選擇日期', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844));

    final recordsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('紀錄'),
    );
    await tester.tap(recordsDestination);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar-date-button')));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.text('選擇飲食紀錄日期'), findsOneWidget);
  });

  testWidgets('桌面寬度顯示側邊導覽並可切換到管理後台', (tester) async {
    await pumpApp(
      tester,
      surfaceSize: const Size(1280, 800),
      initialUser: adminUser,
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    final adminDestination = find.descendant(
      of: find.byType(NavigationRail),
      matching: find.text('管理'),
    );
    await tester.tap(adminDestination);
    await tester.pumpAndSettle();

    expect(find.text('管理後台'), findsOneWidget);
  });

  testWidgets('會員頁可以切換深色模式', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844));

    final profileDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('會員'),
    );
    await tester.tap(profileDestination);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });

  testWidgets('會員可以登出並回到登入頁', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844));

    final profileDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('會員'),
    );
    await tester.tap(profileDestination);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pumpAndSettle();

    expect(find.text('歡迎回來'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('使用者可以搜尋食物並新增飲食紀錄', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844));

    final recordsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('紀錄'),
    );
    await tester.tap(recordsDestination);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-record-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('food-search-field')), '香蕉');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('food-option-6')));
    await tester.enterText(
      find.byKey(const Key('record-quantity-field')),
      '120',
    );
    await tester.tap(find.byKey(const Key('save-record-button')));
    await tester.pumpAndSettle();

    expect(find.text('香蕉'), findsOneWidget);
    expect(find.textContaining('107 kcal'), findsOneWidget);
  });
}
