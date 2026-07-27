import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/app/bootstrap/web_font_loader.dart';

void main() {
  test('Web 字型無法取得時不會阻止應用程式啟動', () async {
    await expectLater(loadWebFonts(), completes);
  });
}
