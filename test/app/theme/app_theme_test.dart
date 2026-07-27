import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/app/theme/app_fonts.dart';
import 'package:food_ledger_frontend/app/theme/app_theme.dart';

void main() {
  test('亮色與暗色主題皆使用隨 Web 一起部署的中文字型', () {
    expect(
      AppTheme.light.textTheme.bodyMedium?.fontFamily,
      AppFonts.notoSansTc,
    );
    expect(AppTheme.dark.textTheme.bodyMedium?.fontFamily, AppFonts.notoSansTc);
  });
}
