import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/feature_overview_page.dart';
import '../../authentication/presentation/providers/auth_providers.dart';
import 'providers/body_profile_providers.dart';

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
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: '登出',
                    message: '確定要登出 FoodLedger 嗎？',
                    confirmLabel: '登出',
                  );
                  if (!confirmed) return;
                  if (!context.mounted) return;
                  await ref.read(authenticationProvider.notifier).signOut();
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
          const SizedBox(height: AppSpacing.medium),
          ref
              .watch(bodyProfileProvider)
              .when(
                loading: () => const Card(
                  child: ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('正在載入身體資料'),
                  ),
                ),
                error: (_, _) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: const Text('無法載入身體資料'),
                    trailing: TextButton(
                      onPressed: () =>
                          ref.read(bodyProfileProvider.notifier).reload(),
                      child: const Text('重試'),
                    ),
                  ),
                ),
                data: (profile) => Card(
                  child: ListTile(
                    key: const Key('body-profile-status'),
                    leading: Icon(
                      profile == null
                          ? Icons.info_outline
                          : Icons.check_circle_outline,
                    ),
                    title: Text(profile == null ? '尚未建立身體資料' : '身體資料已建立'),
                    subtitle: Text(
                      profile == null
                          ? '建立後可用於估算每日熱量與營養目標。'
                          : '可隨時查看或編輯已保存的完整資料。',
                    ),
                    trailing: FilledButton(
                      key: const Key('open-body-profile-button'),
                      onPressed: () => context.push(AppRoutes.bodyProfile),
                      child: Text(profile == null ? '馬上建立' : '查看編輯'),
                    ),
                  ),
                ),
              ),
        ],
      ),
      items: [
        FeatureOverviewItem(
          title: '基本資料',
          description: '管理出生日期、身高、健身目標與活動程度。',
          icon: Icons.badge_outlined,
          onTap: () => context.push(AppRoutes.bodyProfile),
        ),
        const FeatureOverviewItem(
          title: '營養目標',
          description: '設定每日熱量與主要營養素目標。',
          icon: Icons.flag_outlined,
        ),
        const FeatureOverviewItem(
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
