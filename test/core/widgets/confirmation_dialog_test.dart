import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/widgets/confirmation_dialog.dart';

void main() {
  testWidgets('共用確認 Dialog 取消時回傳 false', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showConfirmationDialog(
                  context,
                  title: '刪除資料',
                  message: '資料刪除後無法復原。',
                  confirmLabel: '刪除',
                  isDestructive: true,
                );
              },
              child: const Text('開啟'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('開啟'));
    await tester.pumpAndSettle();

    expect(find.text('刪除資料'), findsOneWidget);
    expect(find.text('資料刪除後無法復原。'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmation-cancel-button')));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('共用確認 Dialog 確認時回傳 true', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showConfirmationDialog(
                  context,
                  title: '登出',
                  message: '確定要登出嗎？',
                  confirmLabel: '登出',
                );
              },
              child: const Text('開啟'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('開啟'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmation-confirm-button')));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
