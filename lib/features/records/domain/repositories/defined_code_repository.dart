import '../models/meal_type_option.dart';

/// 提供後端目前啟用的通用代碼選項。
abstract interface class DefinedCodeRepository {
  Future<List<MealTypeOption>> getMealTypes({required String langCode});
}
