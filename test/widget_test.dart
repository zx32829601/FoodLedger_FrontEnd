import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/app/app.dart';
import 'package:food_ledger_frontend/core/widgets/app_brand_banner.dart';
import 'package:food_ledger_frontend/features/authentication/data/mock_auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/domain/models/app_user.dart';
import 'package:food_ledger_frontend/features/authentication/domain/repositories/auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/presentation/providers/auth_providers.dart';
import 'package:food_ledger_frontend/features/records/presentation/widgets/daily_record_bar.dart';

void main() {
  const memberUser = AppUser(
    id: 'member-1',
    userAccount: 'member',
    displayName: '測試會員',
    email: 'member@example.com',
    isAdmin: false,
  );
  const adminUser = AppUser(
    id: 'admin-1',
    userAccount: 'admin',
    displayName: '測試管理員',
    email: 'admin@example.com',
    isAdmin: true,
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    required Size surfaceSize,
    AppUser? initialUser = memberUser,
    AuthRepository? authRepository,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialAuthUserProvider.overrideWithValue(initialUser),
          authRepositoryProvider.overrideWithValue(
            authRepository ?? MockAuthRepository(),
          ),
        ],
        child: const FoodLedgerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('未登入使用者會導向登入頁', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);

    expect(find.text('歡迎回來'), findsOneWidget);
    expect(find.byKey(const Key('auth-login-id-field')), findsOneWidget);
    expect(find.byType(AppBrandBanner), findsOneWidget);
    expect(find.byKey(const Key('app-brand-logo')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('登入欄位可輸入使用者帳號，不強制使用 Email 格式', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);

    await tester.enterText(
      find.byKey(const Key('auth-login-id-field')),
      'member_account',
    );
    await tester.tap(find.byKey(const Key('auth-password-field')));
    await tester.pump();

    expect(find.text('請輸入使用者帳號或電子郵件'), findsNothing);
    expect(find.text('請輸入有效的電子郵件'), findsNothing);
  });

  testWidgets('點擊登入時會檢查整張表單', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);

    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pump();

    expect(find.text('請輸入使用者帳號或電子郵件'), findsOneWidget);
    expect(find.text('請輸入密碼'), findsOneWidget);
  });

  testWidgets('註冊密碼出現錯誤後會在符合後端規則時立即清除', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);

    await tester.tap(find.byKey(const Key('switch-auth-mode-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pump();
    expect(find.text('密碼至少需要 8 個字元'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      ['A', 'a', ...List.filled(5, '1')].join(),
    );
    await tester.pump();
    expect(find.text('密碼至少需要 8 個字元'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      ['A', 'a', ...List.filled(6, '1')].join(),
    );
    await tester.pump();
    expect(find.text('密碼至少需要 8 個字元'), findsNothing);
  });

  testWidgets('使用者可以登入並進入首頁', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);
    final validPassword = ['A', 'a', ...List.filled(6, '1')].join();

    await tester.enterText(
      find.byKey(const Key('auth-login-id-field')),
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
    final validPassword = ['A', 'a', ...List.filled(6, '1')].join();

    await tester.tap(find.byKey(const Key('switch-auth-mode-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('auth-user-account-field')),
      'new_member',
    );
    await tester.enterText(
      find.byKey(const Key('auth-display-name-field')),
      '新會員',
    );
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

  testWidgets('註冊表單會驗證帳號與顯示名稱規則', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844), initialUser: null);

    await tester.tap(find.byKey(const Key('switch-auth-mode-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('auth-user-account-field')),
      'bad account',
    );
    await tester.enterText(
      find.byKey(const Key('auth-display-name-field')),
      '   ',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pump();

    expect(find.text('帳號須為 4–30 個英文字母、數字、底線或連字號'), findsOneWidget);
    expect(find.text('顯示名稱須為 1–30 個字元，且不可全為空白'), findsOneWidget);
  });

  testWidgets('後端註冊欄位錯誤會顯示在對應欄位並保留追蹤碼', (tester) async {
    await pumpApp(
      tester,
      surfaceSize: const Size(390, 844),
      initialUser: null,
      authRepository: _DuplicateUserAccountRepository(),
    );

    await tester.tap(find.byKey(const Key('switch-auth-mode-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('auth-user-account-field')),
      'existing_user',
    );
    await tester.enterText(
      find.byKey(const Key('auth-display-name-field')),
      '測試會員',
    );
    await tester.enterText(
      find.byKey(const Key('auth-email-field')),
      'member@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      'Password1',
    );
    await tester.enterText(
      find.byKey(const Key('confirm-password-field')),
      'Password1',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('此使用者帳號已被註冊'), findsOneWidget);
    expect(find.text('錯誤追蹤碼：register-trace-id'), findsOneWidget);
  });

  testWidgets('手機寬度顯示底部導覽並可切換到紀錄頁', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(AppBrandBanner), findsOneWidget);
    expect(find.byKey(const Key('app-brand-logo')), findsOneWidget);
    expect(find.text('今天吃得怎麼樣？'), findsOneWidget);
    expect(find.text('今日飲食'), findsOneWidget);
    expect(find.byType(DailyRecordBar), findsWidgets);
    final initialIndicatorCenter = tester.getCenter(
      find.byKey(const Key('navigation-selection-indicator')),
    );

    final recordsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('紀錄'),
    );
    await tester.tap(recordsDestination);
    await tester.pump();

    final slidingBody = tester.widget<AnimatedSlide>(
      find.byKey(const Key('navigation-slide-animation')),
    );
    expect(slidingBody.offset.dx, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 80));
    final movingIndicatorCenter = tester.getCenter(
      find.byKey(const Key('navigation-selection-indicator')),
    );
    expect(movingIndicatorCenter.dx, greaterThan(initialIndicatorCenter.dx));

    await tester.pumpAndSettle();
    final finalIndicatorCenter = tester.getCenter(
      find.byKey(const Key('navigation-selection-indicator')),
    );
    expect(finalIndicatorCenter.dx, greaterThan(movingIndicatorCenter.dx));

    expect(find.text('飲食紀錄'), findsOneWidget);
    expect(find.byType(DailyRecordBar), findsWidgets);
  });

  testWidgets('底部導覽向左切換時選取背景會反向滑動', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(390, 844));

    final profileDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('會員'),
    );
    await tester.tap(profileDestination);
    await tester.pumpAndSettle();
    final profileIndicatorCenter = tester.getCenter(
      find.byKey(const Key('navigation-selection-indicator')),
    );

    final homeDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('首頁'),
    );
    await tester.tap(homeDestination);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final movingIndicatorCenter = tester.getCenter(
      find.byKey(const Key('navigation-selection-indicator')),
    );
    expect(movingIndicatorCenter.dx, lessThan(profileIndicatorCenter.dx));

    await tester.pumpAndSettle();
    final homeIndicatorCenter = tester.getCenter(
      find.byKey(const Key('navigation-selection-indicator')),
    );
    expect(homeIndicatorCenter.dx, lessThan(movingIndicatorCenter.dx));
    expect(find.text('今天吃得怎麼樣？'), findsOneWidget);
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
    expect(find.byType(AppBrandBanner), findsOneWidget);
    expect(find.byKey(const Key('app-brand-logo')), findsOneWidget);

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

class _DuplicateUserAccountRepository implements AuthRepository {
  @override
  Future<AppUser> register({
    required String userAccount,
    required String displayName,
    required String email,
    required String password,
  }) {
    throw const AuthException(
      '請確認輸入資料是否正確',
      code: 'Validation.Failed',
      fieldErrors: {
        'userAccount': AuthFieldFailure(
          code: 'Auth.UserAccountAlreadyExists',
          message: 'Backend fallback message',
        ),
      },
      traceId: 'register-trace-id',
    );
  }

  @override
  Future<AppUser> signIn({required String loginId, required String password}) {
    throw UnimplementedError();
  }

  @override
  void signOut() {}
}
