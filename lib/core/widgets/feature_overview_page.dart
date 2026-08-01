import 'package:flutter/material.dart';

import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Prototype 階段用來呈現功能區塊與頁面目的的共用版型。
class FeatureOverviewPage extends StatelessWidget {
  const FeatureOverviewPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    this.headerAction,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<FeatureOverviewItem> items;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PageHeader(title: title, subtitle: subtitle, icon: icon),
                if (headerAction != null) ...[
                  const SizedBox(height: AppSpacing.large),
                  headerAction!,
                ],
                const SizedBox(height: AppSpacing.extraLarge),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columnCount =
                        constraints.maxWidth >= AppBreakpoints.wide
                        ? 3
                        : constraints.maxWidth >= AppBreakpoints.compact
                        ? 2
                        : 1;
                    final totalSpacing = AppSpacing.medium * (columnCount - 1);
                    final cardWidth =
                        (constraints.maxWidth - totalSpacing) / columnCount;

                    return Wrap(
                      spacing: AppSpacing.medium,
                      runSpacing: AppSpacing.medium,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: cardWidth,
                            child: _OverviewCard(item: item),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureOverviewItem {
  const FeatureOverviewItem({
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: AppRadius.mediumBorderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.extraSmall),
              Text(subtitle, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item});

  final FeatureOverviewItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: AppRadius.mediumBorderRadius,
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: theme.colorScheme.secondary),
              const SizedBox(height: AppSpacing.medium),
              Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(item.description, style: theme.textTheme.bodyMedium),
              if (item.onTap != null) ...[
                const SizedBox(height: AppSpacing.medium),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.arrow_forward),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
