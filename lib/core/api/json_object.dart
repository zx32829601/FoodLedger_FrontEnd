import 'api_exception.dart';

/// 將外部 JSON 邊界轉成具名欄位可安全讀取的物件。
Map<String, Object?> requireJsonObject(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw const ApiException(message: '伺服器回應格式不正確');
}
