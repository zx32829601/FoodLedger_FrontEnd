import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';
import 'app_destination.dart';

/// 依畫面寬度切換手機底部導覽與桌面側邊導覽。
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _selectDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(
      authenticationProvider.select((state) => state.user?.isAdmin == true),
    );
    final destinations = isAdmin
        ? appDestinations
        : appDestinations.take(3).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.expanded) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _selectDestination,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
          );
        }

        final isExtended = constraints.maxWidth >= AppBreakpoints.wide;

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.small,
                  ),
                  child: NavigationRail(
                    extended: isExtended,
                    minExtendedWidth: 216,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _selectDestination,
                    leading: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.large),
                      child: _BrandMark(showLabel: isExtended),
                    ),
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: navigationShell),
            ],
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.showLabel});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.restaurant_menu, color: colorScheme.primary),
        if (showLabel) ...[
          const SizedBox(width: AppSpacing.small),
          Text(
            'FoodLedger',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
