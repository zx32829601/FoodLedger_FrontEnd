/// ASP.NET Core Identity Bearer Token 回應所需的 Session 資料。
class AuthTokens {
  const AuthTokens({
    required this.tokenType,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String tokenType;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
}

/// 僅在應用程式記憶體中保存 Token，避免 Flutter Web 寫入不安全的持久儲存。
class AuthTokenStore {
  AuthTokens? _tokens;

  AuthTokens? get tokens => _tokens;
  String? get accessToken => _tokens?.accessToken;

  void save(AuthTokens tokens) {
    _tokens = tokens;
  }

  void clear() {
    _tokens = null;
  }
}
