import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/nutrient_codes.dart';
import '../../domain/models/nutrition_summary.dart';
import '../../domain/models/weekly_nutrition_summary.dart';
import '../nutrient_amount_formatter.dart';
import '../nutrient_labels.dart';

const _swipeVelocityThreshold = 250.0;
const _dayMetricWidth = 132.0;

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
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  for (final code in NutrientCodes.core)
                    _NutrientChip(code: code, nutrient: summary.nutrient(code)),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final day in summary.days)
                      SizedBox(
                        width: _dayMetricWidth,
                        child: _DayMetric(day: day),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _monthDay(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}

class _DayMetric extends StatelessWidget {
  const _DayMetric({required this.day});

  final DailyNutritionBreakdown day;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _weekday(day.date),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.extraSmall),
        for (final code in NutrientCodes.core)
          Text(
            '${shortNutrientLabel(code)} '
            '${formatNutrientAmount(day.nutrient(code))}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  static String _weekday(DateTime date) {
    const labels = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    return labels[date.weekday - 1];
  }
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({required this.code, required this.nutrient});

  final String code;
  final NutrientAmount? nutrient;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '${nutrient?.displayName ?? fallbackNutrientLabel(code)} '
        '${formatNutrientAmount(nutrient)}',
      ),
    );
  }
}
