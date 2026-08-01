/// 後端 DefinedCode 提供的一個可用餐別選項。
class MealTypeOption {
  const MealTypeOption({
    required this.code,
    required this.displayName,
    required this.sortOrder,
    this.langCode,
    this.note,
  });

  final String code;
  final String displayName;
  final int sortOrder;
  final String? langCode;
  final String? note;
}
