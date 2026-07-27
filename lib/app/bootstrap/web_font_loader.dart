import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../theme/app_fonts.dart';

const _notoSansTcPath = 'fonts/NotoSansTC-VF.ttf';

/// 在 Web 啟動前載入同源的繁體中文字型，避免系統 fallback 字型延遲造成方框。
Future<void> loadWebFonts() async {
  if (!kIsWeb) {
    return;
  }

  try {
    final response = await Dio().get<List<int>>(
      Uri.base.resolve(_notoSansTcPath).toString(),
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Web 中文字型內容為空。');
    }

    final fontLoader = FontLoader(AppFonts.notoSansTc);
    fontLoader.addFont(
      Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))),
    );
    await fontLoader.load();
  } on Object catch (error, stackTrace) {
    debugPrint('無法載入 Web 中文字型：$error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
