/// 管理員食物編輯表單使用的完整資料。
class AdminFood {
  const AdminFood({
    required this.id,
    required this.code,
    required this.translations,
    required this.nutrients,
  });

  final int id;
  final String code;
  final Map<String, AdminFoodTranslation> translations;
  final Map<String, double> nutrients;

  String get displayName =>
      translations['zh-TW']?.displayName ??
      translations['en-US']?.displayName ??
      code;
}

/// 食物單一語系的可維護內容。
class AdminFoodTranslation {
  const AdminFoodTranslation({
    required this.displayName,
    required this.description,
  });

  final String displayName;
  final String description;
}
