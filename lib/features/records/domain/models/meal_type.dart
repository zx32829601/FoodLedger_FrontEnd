/// 依飲食紀錄的食用時間分組顯示餐別。
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label => switch (this) {
    MealType.breakfast => '早餐',
    MealType.lunch => '午餐',
    MealType.dinner => '晚餐',
    MealType.snack => '點心',
  };

  int get defaultHour => switch (this) {
    MealType.breakfast => 8,
    MealType.lunch => 12,
    MealType.dinner => 18,
    MealType.snack => 15,
  };

  String get code => switch (this) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch => 'Lunch',
    MealType.dinner => 'Dinner',
    MealType.snack => 'Snack',
  };

  static MealType? fromCode(String? code) {
    for (final mealType in values) {
      if (mealType.code == code) return mealType;
    }
    return null;
  }

  static MealType fromConsumedAt(DateTime consumedAt) {
    final hour = consumedAt.toLocal().hour;

    if (hour < 11) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 17) return MealType.snack;
    return MealType.dinner;
  }
}
