import 'package:flutter/material.dart';

import '../../../core/widgets/feature_overview_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureOverviewPage(
      title: '管理後台',
      subtitle: '管理使用者、食物基礎資料與系統操作紀錄。',
      icon: Icons.admin_panel_settings_outlined,
      items: [
        FeatureOverviewItem(
          title: '使用者管理',
          description: '搜尋使用者並管理帳號狀態與角色。',
          icon: Icons.manage_accounts_outlined,
        ),
        FeatureOverviewItem(
          title: '食物資料',
          description: '維護食物、分類、份量與營養素資料。',
          icon: Icons.restaurant_outlined,
        ),
        FeatureOverviewItem(
          title: '系統紀錄',
          description: '查看 Audit Log，未來透過後端整合 ELK 搜尋。',
          icon: Icons.monitor_heart_outlined,
        ),
      ],
    );
  }
}
