import '../domain/models/meal_type_option.dart';
import '../domain/repositories/defined_code_repository.dart';

/// 提供 Widget 與離線預覽使用的固定 DefinedCode 選項。
class MockDefinedCodeRepository implements DefinedCodeRepository {
  const MockDefinedCodeRepository({
    this.mealTypes = const [
      MealTypeOption(code: 'Breakfast', displayName: '早餐', sortOrder: 1),
      MealTypeOption(code: 'Lunch', displayName: '午餐', sortOrder: 2),
      MealTypeOption(code: 'Dinner', displayName: '晚餐', sortOrder: 3),
      MealTypeOption(code: 'Snack', displayName: '點心', sortOrder: 4),
    ],
  });

  final List<MealTypeOption> mealTypes;

  @override
  Future<List<MealTypeOption>> getMealTypes({required String langCode}) async {
    return List.unmodifiable(mealTypes);
  }
}
