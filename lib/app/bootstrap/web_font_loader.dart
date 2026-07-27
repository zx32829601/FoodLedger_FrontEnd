import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../theme/app_fonts.dart';

const _notoSansTcPath = 'fonts/NotoSansTC-VF.ttf';

/// 在 Web 啟動前載入同源的繁體中文字型，避免系統 fallback 字型延遲造成方框。
Future<void> loadWebFonts() async {
  if (!kIsWeb) {
    return;
  }

  final fontLoader = FontLoader(AppFonts.notoSansTc);
  fontLoader.addFont(NetworkAssetBundle(Uri.base).load(_notoSansTcPath));

  try {
    await fontLoader.load();
  } on Object catch (error, stackTrace) {
    debugPrint('無法載入 Web 中文字型：$error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
