import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../records/domain/models/daily_record.dart';
import '../../records/presentation/providers/record_providers.dart';
import '../../records/presentation/widgets/daily_record_bar.dart';
import '../../records/presentation/widgets/nutrition_summary_card.dart';
import 'providers/home_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(homeTodayProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(homeNutritionSummaryProvider);
    final records = ref.watch(homeDailyRecordsProvider);
    final mealTypeLabels = ref
        .watch(mealTypeOptionsProvider)
        .when(
          data: (options) => {
            for (final option in options) option.code: option.displayName,
          },
          loading: () => const <String, String>{},
          error: (error, stackTrace) => const <String, String>{},
        );

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
                  onAddRecord: () => context.go(AppRoutes.foodSearch),
                ),
                const SizedBox(height: AppSpacing.large),
                summary.when(
                  data: (value) => NutritionSummaryCard(
                    summary: value,
                    mealTypeLabels: mealTypeLabels,
                  ),
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
                  data: (items) => _TodayRecords(
                    records: items,
                    mealTypeLabels: mealTypeLabels,
                  ),
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
  const _TodayRecords({required this.records, required this.mealTypeLabels});

  final List<DailyRecord> records;
  final Map<String, String> mealTypeLabels;

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
      itemBuilder: (context, index) {
        final record = recentRecords[index];
        return DailyRecordBar(
          record: record,
          mealTypeDisplayName:
              mealTypeLabels[record.mealTypeCode] ?? record.mealTypeCode,
        );
      },
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
