import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/app/app.dart';

void main() {
  testWidgets('啟動應用程式時顯示 FoodLedger 初始化畫面', (tester) async {
    await tester.pumpWidget(const FoodLedgerApp());

    expect(find.text('FoodLedger'), findsOneWidget);
    expect(find.text('專案初始化完成'), findsOneWidget);
    expect(find.text('下一步將建立設計系統與響應式導覽架構。'), findsOneWidget);
  });
}
