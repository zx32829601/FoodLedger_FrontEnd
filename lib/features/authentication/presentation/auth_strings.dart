import '../domain/repositories/auth_repository.dart';

/// 身分驗證畫面的繁體中文文案邊界。
abstract final class AuthStrings {
  static const registerTitle = '建立會員帳號';
  static const loginTitle = '歡迎回來';
  static const registerSubtitle = '開始記錄每日飲食與營養目標。';
  static const loginSubtitle = '登入後繼續管理你的飲食紀錄。';
  static const userAccountLabel = '使用者帳號';
  static const userAccountHelper = '4–30 個英文字母、數字、底線或連字號';
  static const displayNameLabel = '顯示名稱';
  static const emailLabel = '電子郵件';
  static const loginIdLabel = '使用者帳號或電子郵件';
  static const passwordLabel = '密碼';
  static const passwordHelper = '至少 8 個字元，須包含英文大小寫與數字';
  static const confirmPasswordLabel = '確認密碼';
  static const showPassword = '顯示密碼';
  static const hidePassword = '隱藏密碼';
  static const registerButton = '註冊';
  static const loginButton = '登入';
  static const switchToLogin = '已經有帳號？前往登入';
  static const switchToRegister = '還沒有帳號？建立會員帳號';
  static const loginIdRequired = '請輸入使用者帳號或電子郵件';
  static const userAccountInvalid = '帳號須為 4–30 個英文字母、數字、底線或連字號';
  static const displayNameInvalid = '顯示名稱須為 1–30 個字元，且不可全為空白';
  static const emailInvalid = '請輸入有效的電子郵件';
  static const passwordRequired = '請輸入密碼';
  static const passwordTooShort = '密碼至少需要 8 個字元';
  static const passwordComplexity = '密碼需包含英文大小寫與數字';
  static const confirmPasswordMismatch = '兩次輸入的密碼不一致';
  static const invalidCredentials = '帳號、電子郵件或密碼不正確';
  static const userAccountAlreadyExists = '此使用者帳號已被註冊';
  static const emailAlreadyExists = '此電子郵件已被註冊';
  static const validationFailed = '請確認輸入資料是否正確';
  static const loginUnavailable = '目前無法登入，請稍後再試';
  static const registerUnavailable = '目前無法註冊，請稍後再試';
  static const sessionExpired = '登入狀態已失效，請重新登入';
  static const traceIdLabel = '錯誤追蹤碼';
  static const prototypeNotice =
      '目前連線 FoodLedger 自訂 Auth API。'
      'API 位址可透過 FOOD_LEDGER_API_BASE_URL 設定。';

  static const _errorMessages = {
    'Auth.InvalidCredentials': invalidCredentials,
    'Auth.UserAccountAlreadyExists': userAccountAlreadyExists,
    'Auth.EmailAlreadyExists': emailAlreadyExists,
    'Auth.UserAccountInvalid': userAccountInvalid,
    'Auth.DisplayNameInvalid': displayNameInvalid,
    'Auth.EmailInvalid': emailInvalid,
    'Auth.PasswordInvalid': passwordHelper,
    'Validation.Failed': validationFailed,
  };

  static String errorMessage({
    required String? code,
    required String fallback,
  }) {
    return _errorMessages[code] ?? fallback;
  }

  static String fieldErrorMessage(AuthFieldFailure error) {
    return _errorMessages[error.code] ?? error.message;
  }
}
