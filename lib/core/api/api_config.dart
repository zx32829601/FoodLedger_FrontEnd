/// FoodLedger API 的非敏感執行環境設定。
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'FOOD_LEDGER_API_BASE_URL',
    defaultValue: 'https://localhost:7041',
  );

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);
}
