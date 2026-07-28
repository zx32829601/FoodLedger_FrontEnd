import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/nutrient_codes.dart';
import '../../domain/models/nutrition_summary.dart';
import '../../domain/models/weekly_nutrition_summary.dart';
import '../nutrient_amount_formatter.dart';
import '../nutrient_labels.dart';

const _swipeVelocityThreshold = 250.0;

// 寬版採四欄兩列，窄版改成兩欄四列以保留營養素全名的可讀空間。
const _weeklyGridWideBreakpoint = 720.0;

// 每格保留標題、日期與四項核心營養素換行所需的高度。
const _weeklyGridTileExtent = 216.0;

class WeeklyNutritionSummaryCard extends StatelessWidget {
  const WeeklyNutritionSummaryCard({
    required this.summary,
    required this.onPreviousWeek,
    required this.onNextWeek,
    super.key,
  });

  final WeeklyNutritionSummary summary;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > _swipeVelocityThreshold) {
          onPreviousWeek();
        } else if (velocity < -_swipeVelocityThreshold) {
          onNextWeek();
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    key: const Key('previous-week-button'),
                    tooltip: '上一週',
                    onPressed: onPreviousWeek,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '每週營養摘要',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_monthDay(summary.startDate)}–'
                          '${_monthDay(summary.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('next-week-button'),
                    tooltip: '下一週',
                    onPressed: onNextWeek,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columnCount =
                      constraints.maxWidth >= _weeklyGridWideBreakpoint ? 4 : 2;
                  return GridView.builder(
                    key: const Key('weekly-nutrition-grid'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.days.length + 1,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      crossAxisSpacing: AppSpacing.small,
                      mainAxisSpacing: AppSpacing.small,
                      mainAxisExtent: _weeklyGridTileExtent,
                    ),
                    itemBuilder: (context, index) {
                      if (index < summary.days.length) {
                        final day = summary.days[index];
                        final keyPrefix = 'weekly-day-${_dateKey(day.date)}';
                        return _NutritionGridTile(
                          key: Key(keyPrefix),
                          keyPrefix: keyPrefix,
                          title: _weekday(day.date),
                          subtitle: _monthDay(day.date),
                          nutrients: day.totals,
                        );
                      }

                      return _NutritionGridTile(
                        key: const Key('weekly-total'),
                        keyPrefix: 'weekly-total',
                        title: '本週總計',
                        subtitle: '七日營養合計',
                        nutrients: summary.totals,
                        isWeeklyTotal: true,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionGridTile extends StatelessWidget {
  const _NutritionGridTile({
    required this.keyPrefix,
    required this.title,
    required this.subtitle,
    required this.nutrients,
    this.isWeeklyTotal = false,
    super.key,
  });

  final String keyPrefix;
  final String title;
  final String subtitle;
  final List<NutrientAmount> nutrients;
  final bool isWeeklyTotal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isWeeklyTotal
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerLow;
    final borderColor = isWeeklyTotal
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: AppSpacing.large),
          for (final code in NutrientCodes.core)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.extraSmall),
              child: _NutrientLine(
                textKey: Key('$keyPrefix-nutrient-$code'),
                code: code,
                nutrient: nutrients.nutrientByCode(code),
              ),
            ),
        ],
      ),
    );
  }
}

class _NutrientLine extends StatelessWidget {
  const _NutrientLine({
    required this.textKey,
    required this.code,
    required this.nutrient,
  });

  final Key textKey;
  final String code;
  final NutrientAmount? nutrient;

  @override
  Widget build(BuildContext context) {
    final label = nutrient?.displayName ?? fallbackNutrientLabel(code);
    return Text.rich(
      key: textKey,
      TextSpan(
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: formatNutrientAmount(nutrient),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

String _monthDay(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _weekday(DateTime date) {
  const labels = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
  return labels[date.weekday - 1];
}
