import 'package:flutter/material.dart';

/// App Shell 中的一個主要導覽目的地。
class AppDestination {
  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const appDestinations = [
  AppDestination(
    label: '首頁',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  AppDestination(
    label: '紀錄',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  AppDestination(
    label: '食物',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
  ),
  AppDestination(
    label: '會員',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
  AppDestination(
    label: '管理',
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings,
  ),
];
