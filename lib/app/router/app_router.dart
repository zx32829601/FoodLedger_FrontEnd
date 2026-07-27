import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_page.dart';
import '../../features/authentication/presentation/authentication_page.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/records/presentation/records_page.dart';
import '../../features/records/presentation/food_search_page.dart';
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
      final isSessionRestoreRoute =
          state.matchedLocation == AppRoutes.sessionRestore;

      if (authState.isRestoring) {
        if (isSessionRestoreRoute) {
          return null;
        }
        return Uri(
          path: AppRoutes.sessionRestore,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      if (!authState.isAuthenticated) {
        if (isAuthenticationRoute) {
          return null;
        }
        final returnLocation = isSessionRestoreRoute
            ? _safeReturnLocation(state.uri.queryParameters['from'])
            : state.uri.toString();
        return Uri(
          path: AppRoutes.login,
          queryParameters: {'from': returnLocation},
        ).toString();
      }

      if (state.matchedLocation == AppRoutes.admin &&
          authState.user?.isAdmin != true) {
        return AppRoutes.home;
      }

      if (isAuthenticationRoute) {
        return _safeReturnLocation(state.uri.queryParameters['from']);
      }

      if (isSessionRestoreRoute) {
        return _safeReturnLocation(state.uri.queryParameters['from']);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.home),
      GoRoute(
        path: AppRoutes.sessionRestore,
        builder: (context, state) => const _SessionRestorePage(),
      ),
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
                path: AppRoutes.foodSearch,
                builder: (context, state) => const FoodSearchPage(),
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
      location.startsWith(AppRoutes.sessionRestore) ||
      location.startsWith(AppRoutes.login) ||
      location.startsWith(AppRoutes.register)) {
    return AppRoutes.home;
  }
  return location;
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _SessionRestorePage extends StatelessWidget {
  const _SessionRestorePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
