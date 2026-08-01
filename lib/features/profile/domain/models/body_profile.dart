/// 使用者用於熱量與營養目標計算的完整身體資料。
class BodyProfile {
  const BodyProfile({
    required this.birthDate,
    required this.biologicalSexCode,
    required this.heightInCentimeters,
    required this.fitnessGoalCode,
    required this.activityLevelCode,
    required this.timeZone,
    this.version,
  });

  final DateTime birthDate;
  final String biologicalSexCode;
  final double heightInCentimeters;
  final String fitnessGoalCode;
  final String activityLevelCode;
  final String timeZone;
  final String? version;
}
