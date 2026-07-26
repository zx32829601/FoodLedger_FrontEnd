import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/nutrition_summary.dart';

class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard({
    required this.summary,
    this.calorieGoal = 2000,
    super.key,
  });

  final NutritionSummary summary;
  final double calorieGoal;

  @override
  Widget build(BuildContext context) {
    final progress = (summary.calories / calorieGoal).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '今日營養',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${summary.calories.toStringAsFixed(0)} / '
                  '${calorieGoal.toStringAsFixed(0)} kcal',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: AppSpacing.large),
            Wrap(
              spacing: AppSpacing.extraLarge,
              runSpacing: AppSpacing.medium,
              children: [
                _NutritionMetric(
                  label: '蛋白質',
                  value: '${summary.protein.toStringAsFixed(1)} g',
                ),
                _NutritionMetric(
                  label: '脂肪',
                  value: '${summary.fat.toStringAsFixed(1)} g',
                ),
                _NutritionMetric(
                  label: '碳水',
                  value: '${summary.carbohydrates.toStringAsFixed(1)} g',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionMetric extends StatelessWidget {
  const _NutritionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
