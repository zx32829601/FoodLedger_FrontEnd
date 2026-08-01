/// 後端 DefinedCode API 提供的身體資料選項。
class BodyProfileOption {
  const BodyProfileOption({
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

typedef BodyProfileOptions = ({
  List<BodyProfileOption> fitnessGoals,
  List<BodyProfileOption> activityLevels,
});
