import 'package:flutter/material.dart';

import 'app_destination.dart';

/// 讓選取背景在目的地之間滑動，同時保留 Material 3 導覽列行為。
class SlidingNavigationBar extends StatelessWidget {
  const SlidingNavigationBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  static const _animationDuration = Duration(milliseconds: 280);
  static const _defaultHeight = 80.0;
  static const _indicatorWidth = 64.0;
  static const _indicatorHeight = 32.0;
  static const _indicatorTop = 12.0;
  static const _indicatorBorderRadius = BorderRadius.all(Radius.circular(20));

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final navigationBarTheme = NavigationBarTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final barHeight = navigationBarTheme.height ?? _defaultHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final destinationWidth = constraints.maxWidth / destinations.length;
        final indicatorLeft =
            (destinationWidth * selectedIndex) +
            ((destinationWidth - _indicatorWidth) / 2);

        return SizedBox(
          height: barHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color:
                      navigationBarTheme.backgroundColor ??
                      colorScheme.surfaceContainer,
                ),
              ),
              AnimatedPositioned(
                duration: disableAnimations
                    ? Duration.zero
                    : _animationDuration,
                curve: Curves.easeOutCubic,
                left: indicatorLeft,
                top: _indicatorTop,
                child: IgnorePointer(
                  child: SizedBox(
                    key: const Key('navigation-selection-indicator'),
                    width: _indicatorWidth,
                    height: _indicatorHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            navigationBarTheme.indicatorColor ??
                            colorScheme.secondaryContainer,
                        borderRadius: _indicatorBorderRadius,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: NavigationBar(
                  height: barHeight,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  animationDuration: disableAnimations
                      ? Duration.zero
                      : _animationDuration,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: [
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
