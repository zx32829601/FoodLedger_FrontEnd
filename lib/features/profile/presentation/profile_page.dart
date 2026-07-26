import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../core/widgets/feature_overview_page.dart';
import '../../authentication/presentation/providers/auth_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(
      authenticationProvider.select((state) => state.user),
    );

    return FeatureOverviewPage(
      title: '會員中心',
      subtitle: '管理個人資料、營養目標與應用程式偏好。',
      icon: Icons.person_outline,
      headerAction: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mediumBorderRadius,
            ),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(_userInitial(user?.displayName)),
              ),
              title: Text(user?.displayName ?? 'FoodLedger 使用者'),
              subtitle: Text(user?.email ?? ''),
              trailing: OutlinedButton.icon(
                key: const Key('logout-button'),
                onPressed: () {
                  ref.read(authenticationProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('登出'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Card(
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mediumBorderRadius,
            ),
            child: SwitchListTile(
              title: const Text('深色模式'),
              subtitle: const Text('切換 FoodLedger 的亮色與暗色外觀'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: themeMode == ThemeMode.dark,
              onChanged: (enabled) {
                ref
                    .read(themeModeProvider.notifier)
                    .setDarkMode(enabled: enabled);
              },
            ),
          ),
        ],
      ),
      items: const [
        FeatureOverviewItem(
          title: '基本資料',
          description: '管理名稱、身高、體重與活動程度。',
          icon: Icons.badge_outlined,
        ),
        FeatureOverviewItem(
          title: '營養目標',
          description: '設定每日熱量與主要營養素目標。',
          icon: Icons.flag_outlined,
        ),
        FeatureOverviewItem(
          title: '帳號安全',
          description: '管理密碼、登入狀態與登出操作。',
          icon: Icons.security_outlined,
        ),
      ],
    );
  }
}

String _userInitial(String? displayName) {
  final normalizedName = displayName?.trim() ?? '';
  return normalizedName.isEmpty ? 'F' : normalizedName[0].toUpperCase();
}
