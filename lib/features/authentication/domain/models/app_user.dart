/// 已登入使用者在前端需要的最小身分資訊。
class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.isAdmin,
  });

  final String id;
  final String displayName;
  final String email;
  final bool isAdmin;
}
