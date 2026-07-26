import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/app/app.dart';
import 'package:food_ledger_frontend/features/authentication/data/mock_auth_repository.dart';
import 'package:food_ledger_frontend/features/authentication/presentation/providers/auth_providers.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('使用者從登入畫面建立 Session 並返回受保護首頁', (tester) async {
    final validPassword = ['A', 'a', ...List.filled(6, '1')].join();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialAuthUserProvider.overrideWithValue(null),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: const FoodLedgerApp(),
      ),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const Key('auth-login-id-field')),
    );

    await tester.enterText(
      find.byKey(const Key('auth-login-id-field')),
      'member@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      validPassword,
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await _pumpUntilVisible(tester, find.text('今天吃得怎麼樣？'));

    expect(find.text('今天吃得怎麼樣？'), findsOneWidget);
    final hasResponsiveNavigation =
        find.byType(NavigationBar).evaluate().isNotEmpty ||
        find.byType(NavigationRail).evaluate().isNotEmpty;
    expect(hasResponsiveNavigation, isTrue);
  });
}

Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('等待目標 Widget 顯示逾時：$finder');
}
