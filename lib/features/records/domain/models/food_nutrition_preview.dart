import 'nutrition_summary.dart';

/// 驗證食用克數並產生依全域順位排列的營養預覽。
abstract final class FoodNutritionPreview {
  static double? parseQuantity(String text) {
    final normalized = text.trim();
    if (!RegExp(r'^\d+(\.\d)?$').hasMatch(normalized)) return null;
    final quantity = double.tryParse(normalized);
    if (quantity == null || quantity < 0.1 || quantity > 10000) return null;
    return quantity;
  }

  static List<NutrientAmount> calculate(
    Iterable<NutrientAmount> nutrientsPer100Grams,
    double quantityGrams,
  ) {
    final factor = quantityGrams / 100;
    final result = nutrientsPer100Grams
        .map(
          (item) => NutrientAmount(
            nutrientId: item.nutrientId,
            code: item.code,
            displayName: item.displayName,
            langCode: item.langCode,
            amount: item.amount * factor,
            unitCode: item.unitCode,
            displayOrder: item.displayOrder,
          ),
        )
        .toList();
    result.sort((left, right) {
      final order = left.displayOrder.compareTo(right.displayOrder);
      return order == 0 ? left.code.compareTo(right.code) : order;
    });
    return result;
  }
}
