import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../domain/models/daily_record.dart';
import '../domain/models/meal_type.dart';
import 'providers/record_providers.dart';
import 'widgets/add_record_dialog.dart';
import 'widgets/daily_record_bar.dart';
import 'widgets/nutrition_summary_card.dart';

class RecordsPage extends ConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final records = ref.watch(dailyRecordsProvider);
    final summary = ref.watch(nutritionSummaryProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PageHeader(onAddRecord: () => _showAddRecordDialog(context)),
                const SizedBox(height: AppSpacing.large),
                _DateSelector(selectedDate: selectedDate),
                const SizedBox(height: AppSpacing.medium),
                summary.when(
                  data: (value) => NutritionSummaryCard(summary: value),
                  loading: () => const _LoadingCard(height: 146),
                  error: (error, stackTrace) => _ErrorCard(
                    message: '營養統計暫時無法載入',
                    onRetry: () => ref.invalidate(nutritionSummaryProvider),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                Text(
                  '餐別紀錄',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.medium),
                records.when(
                  data: (items) => _RecordsByMeal(records: items),
                  loading: () => const _LoadingCard(height: 180),
                  error: (error, stackTrace) => _ErrorCard(
                    message: '飲食紀錄暫時無法載入',
                    onRetry: () => ref.invalidate(dailyRecordsProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddRecordDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const AddRecordDialog(),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAddRecord});

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
              '飲食紀錄',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.extraSmall),
            Text(
              '記錄吃下的食物，營養統計會即時更新。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        FilledButton.icon(
          key: const Key('add-record-button'),
          onPressed: onAddRecord,
          icon: const Icon(Icons.add),
          label: const Text('新增紀錄'),
        ),
      ],
    );
  }
}

class _DateSelector extends ConsumerWidget {
  const _DateSelector({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.small),
        child: OutlinedButton(
          key: const Key('calendar-date-button'),
          onPressed: () => _showCalendar(context, ref),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.medium,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(selectedDate),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _isToday(selectedDate)
                          ? '今天'
                          : _weekdayLabel(selectedDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCalendar(BuildContext context, WidgetRef ref) async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 1, 12, 31),
      helpText: '選擇飲食紀錄日期',
      cancelText: '取消',
      confirmText: '選擇',
    );

    if (selected != null) {
      ref.read(selectedDateProvider.notifier).select(selected);
    }
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}/$month/$day';
  }

  static bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  static String _weekdayLabel(DateTime date) {
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekdays[date.weekday - 1];
  }
}

class _RecordsByMeal extends ConsumerWidget {
  const _RecordsByMeal({required this.records});

  final List<DailyRecord> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return const _EmptyRecords();
    }

    return Column(
      children: [
        for (final mealType in MealType.values)
          if (records.any((record) => record.mealType == mealType)) ...[
            _MealSection(
              mealType: mealType,
              records: records
                  .where((record) => record.mealType == mealType)
                  .toList(growable: false),
              onDelete: (recordId) async {
                await ref
                    .read(dailyRecordsProvider.notifier)
                    .deleteRecord(recordId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('紀錄已刪除')));
              },
              onEdit: (record) async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => AddRecordDialog(initialRecord: record),
                );
              },
            ),
            const SizedBox(height: AppSpacing.medium),
          ],
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.mealType,
    required this.records,
    required this.onDelete,
    required this.onEdit,
  });

  final MealType mealType;
  final List<DailyRecord> records;
  final ValueChanged<int> onDelete;
  final ValueChanged<DailyRecord> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mealType.label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.small),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return DailyRecordBar(
              record: record,
              onDelete: () => onDelete(record.id),
              onEdit: () => onEdit(record),
            );
          },
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.small),
        ),
      ],
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.extraLarge),
        child: Column(
          children: [
            Icon(
              Icons.no_food_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text('這一天還沒有飲食紀錄', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.small),
            const Text('點選「新增紀錄」開始記錄第一餐。'),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('重試')),
          ],
        ),
      ),
    );
  }
}
