import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// 在所有主要頁面頂端顯示一致的 FoodLedger 品牌識別。
class AppBrandBanner extends StatelessWidget implements PreferredSizeWidget {
  const AppBrandBanner({super.key});

  static const _toolbarHeight = 64.0;
  static const _dividerHeight = 1.0;
  static const logoAssetPath = 'assets/branding/foodledger-banner-logo.png';

  @override
  Size get preferredSize =>
      const Size.fromHeight(_toolbarHeight + _dividerHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _toolbarHeight,
      titleSpacing: AppSpacing.medium,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'FoodLedger 圖標',
            image: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.extraSmall),
              child: Image.asset(
                logoAssetPath,
                key: const Key('app-brand-logo'),
                width: 40,
                height: 40,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            'FoodLedger',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_dividerHeight),
        child: Divider(
          height: _dividerHeight,
          thickness: _dividerHeight,
          color: colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
