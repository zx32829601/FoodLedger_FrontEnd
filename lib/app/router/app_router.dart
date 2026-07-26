import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_page.dart';
import '../../features/authentication/presentation/authentication_page.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/records/presentation/records_page.dart';
import '../shell/app_shell.dart';
import 'app_routes.dart';

/// 提供應用程式路由，並在 ProviderScope 銷毀時釋放資源。
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(authenticationProvider, (_, _) {
    refreshNotifier.notify();
  });

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authenticationProvider);
      final isAuthenticationRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!authState.isAuthenticated) {
        if (isAuthenticationRoute) {
          return null;
        }
        return Uri(
          path: AppRoutes.login,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      if (state.matchedLocation == AppRoutes.admin &&
          authState.user?.isAdmin != true) {
        return AppRoutes.home;
      }

      if (isAuthenticationRoute) {
        return _safeReturnLocation(state.uri.queryParameters['from']);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.home),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const AuthenticationPage(
          key: ValueKey(AppRoutes.login),
          isRegister: false,
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const AuthenticationPage(
          key: ValueKey(AppRoutes.register),
          isRegister: true,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.records,
                builder: (context, state) => const RecordsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.admin,
                builder: (context, state) => const AdminPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(refreshNotifier.dispose);
  ref.onDispose(router.dispose);
  return router;
});

String _safeReturnLocation(String? location) {
  if (location == null ||
      !location.startsWith('/') ||
      location.startsWith('//') ||
      location.startsWith(AppRoutes.login) ||
      location.startsWith(AppRoutes.register)) {
    return AppRoutes.home;
  }
  return location;
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
