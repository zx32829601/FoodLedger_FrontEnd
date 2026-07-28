/// Nutrition API 的預設 IANA 時區。
const defaultNutritionTimeZone = String.fromEnvironment(
  'FOOD_LEDGER_TIME_ZONE',
  defaultValue: 'Asia/Taipei',
);

/// Nutrition API 的預設語系。
const defaultNutritionLangCode = String.fromEnvironment(
  'FOOD_LEDGER_LANG_CODE',
  defaultValue: 'zh-TW',
);
