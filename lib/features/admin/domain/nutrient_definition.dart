class NutrientDefinition {
  const NutrientDefinition({
    required this.nutrientId,
    required this.code,
    required this.displayName,
    required this.unitCode,
    this.langCode,
    this.displayOrder = 1000,
  });

  final int nutrientId;
  final String code;
  final String displayName;
  final String? langCode;
  final String unitCode;
  final int displayOrder;
}
