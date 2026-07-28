import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_brand_banner.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';
import 'app_destination.dart';
import 'sliding_navigation_bar.dart';

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
        : appDestinations.take(4).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.expanded) {
          return Scaffold(
            appBar: const AppBrandBanner(),
            body: ClipRect(
              child: _SlidingNavigationBody(
                selectedIndex: navigationShell.currentIndex,
                child: navigationShell,
              ),
            ),
            bottomNavigationBar: SlidingNavigationBar(
              destinations: destinations,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _selectDestination,
            ),
          );
        }

        final isExtended = constraints.maxWidth >= AppBreakpoints.wide;

        return Scaffold(
          appBar: const AppBrandBanner(),
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

class _SlidingNavigationBody extends StatefulWidget {
  const _SlidingNavigationBody({
    required this.selectedIndex,
    required this.child,
  });

  final int selectedIndex;
  final Widget child;

  @override
  State<_SlidingNavigationBody> createState() => _SlidingNavigationBodyState();
}

class _SlidingNavigationBodyState extends State<_SlidingNavigationBody> {
  static const _slideDistance = 0.08;
  static const _animationDuration = Duration(milliseconds: 280);

  Offset _offset = Offset.zero;
  int _animationRevision = 0;

  @override
  void didUpdateWidget(covariant _SlidingNavigationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == oldWidget.selectedIndex) {
      return;
    }

    _offset = Offset(
      widget.selectedIndex > oldWidget.selectedIndex
          ? _slideDistance
          : -_slideDistance,
      0,
    );
    final revision = ++_animationRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || revision != _animationRevision) {
        return;
      }
      setState(() {
        _offset = Offset.zero;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      key: const Key('navigation-slide-animation'),
      offset: _offset,
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
      child: widget.child,
    );
  }
}
