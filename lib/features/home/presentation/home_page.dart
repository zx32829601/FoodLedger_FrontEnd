import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../records/domain/models/daily_record.dart';
import '../../records/presentation/widgets/add_record_dialog.dart';
import '../../records/presentation/widgets/daily_record_bar.dart';
import '../../records/presentation/widgets/nutrition_summary_card.dart';
import 'providers/home_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeNutritionSummaryProvider);
    final records = ref.watch(homeDailyRecordsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHeader(
                  onAddRecord: () => _showAddRecordDialog(context, ref),
                ),
                const SizedBox(height: AppSpacing.large),
                summary.when(
                  data: (value) => NutritionSummaryCard(summary: value),
                  loading: () => const _HomeLoadingCard(),
                  error: (error, stackTrace) => const _HomeMessageCard(
                    icon: Icons.error_outline,
                    message: '今日營養統計暫時無法載入',
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                Text(
                  '今日飲食',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.medium),
                records.when(
                  data: (items) => _TodayRecords(records: items),
                  loading: () => const _HomeLoadingCard(),
                  error: (error, stackTrace) => const _HomeMessageCard(
                    icon: Icons.error_outline,
                    message: '今日飲食紀錄暫時無法載入',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddRecordDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddRecordDialog(
        recordDate: ref.read(homeTodayProvider),
        onSaved: () => ref.invalidate(homeDailyRecordsProvider),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onAddRecord});

  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今天吃得怎麼樣？',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.extraSmall),
            Text(
              '記下每一餐，逐步靠近今天的營養目標。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        FilledButton.icon(
          key: const Key('home-add-record-button'),
          onPressed: onAddRecord,
          icon: const Icon(Icons.add),
          label: const Text('新增飲食'),
        ),
      ],
    );
  }
}

class _TodayRecords extends StatelessWidget {
  const _TodayRecords({required this.records});

  final List<DailyRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _HomeMessageCard(
        icon: Icons.no_food_outlined,
        message: '今天還沒有紀錄，新增第一餐吧！',
      );
    }

    final recentRecords = records.reversed.take(3).toList(growable: false);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentRecords.length,
      itemBuilder: (context, index) =>
          DailyRecordBar(record: recentRecords[index], showMealType: true),
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.small),
    );
  }
}

class _HomeLoadingCard extends StatelessWidget {
  const _HomeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HomeMessageCard extends StatelessWidget {
  const _HomeMessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.extraLarge),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.small),
            Text(message),
          ],
        ),
      ),
    );
  }
}
