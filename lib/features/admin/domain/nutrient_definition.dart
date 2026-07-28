class NutrientDefinition {
  const NutrientDefinition({
    required this.nutrientId,
    required this.code,
    required this.displayName,
    required this.unitCode,
    this.langCode,
  });

  final int nutrientId;
  final String code;
  final String displayName;
  final String? langCode;
  final String unitCode;
}
