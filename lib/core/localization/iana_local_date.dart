import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;

bool _isTimeZoneDatabaseInitialized = false;

/// 將同一個時間點換算成指定 IANA 時區的年月日。
DateTime localDateInTimeZone(DateTime instant, String timeZoneName) {
  final localDateTime = time_zone.TZDateTime.from(
    instant,
    _location(timeZoneName),
  );
  return DateTime(localDateTime.year, localDateTime.month, localDateTime.day);
}

/// 在指定 IANA 時區建立某日的當地時間。
DateTime localDateTimeInTimeZone(DateTime date, int hour, String timeZoneName) {
  return time_zone.TZDateTime(
    _location(timeZoneName),
    date.year,
    date.month,
    date.day,
    hour,
  );
}

/// 計算指定 IANA 時區距離下一個當地日的實際時間。
///
/// 使用時區資料庫建立隔日零時，因此日光節約時間切換日也不會固定假設為
/// 24 小時。
Duration durationUntilNextLocalDay(DateTime instant, String timeZoneName) {
  final location = _location(timeZoneName);
  final localDateTime = time_zone.TZDateTime.from(instant, location);
  final nextLocalDay = time_zone.TZDateTime(
    location,
    localDateTime.year,
    localDateTime.month,
    localDateTime.day + 1,
  );
  return nextLocalDay.toUtc().difference(instant.toUtc());
}

time_zone.Location _location(String timeZoneName) {
  if (!_isTimeZoneDatabaseInitialized) {
    time_zone_data.initializeTimeZones();
    _isTimeZoneDatabaseInitialized = true;
  }
  return time_zone.getLocation(timeZoneName);
}
