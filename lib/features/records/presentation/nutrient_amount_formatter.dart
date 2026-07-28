import '../domain/models/nutrient_unit_codes.dart';
import '../domain/models/nutrition_summary.dart';

/// 依後端單位格式化營養素；缺少資料時保留破折號語意。
String formatNutrientAmount(NutrientAmount? nutrient) {
  if (nutrient == null) return '—';

  final maximumFractionDigits = switch (nutrient.unitCode.toLowerCase()) {
    NutrientUnitCodes.kilocalorie || NutrientUnitCodes.gram => 1,
    NutrientUnitCodes.milligram ||
    NutrientUnitCodes.microgram ||
    NutrientUnitCodes.microgramSymbol => 2,
    _ => 2,
  };
  final amount = _trimTrailingZeros(
    nutrient.amount.toStringAsFixed(maximumFractionDigits),
  );
  return '$amount ${nutrient.unitCode}';
}

String _trimTrailingZeros(String value) {
  if (!value.contains('.')) return value;
  return value
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
