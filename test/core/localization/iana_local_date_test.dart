import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/localization/iana_local_date.dart';

void main() {
  test('localDateTimeFromInstant 使用指定 IANA 時區換算同一時間點', () {
    final result = localDateTimeFromInstant(
      DateTime.utc(2026, 7, 28, 4, 20),
      'Asia/Taipei',
    );

    expect(result.year, 2026);
    expect(result.month, 7);
    expect(result.day, 28);
    expect(result.hour, 12);
    expect(result.minute, 20);
  });
}
