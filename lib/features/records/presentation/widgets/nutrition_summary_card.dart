import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/meal_type.dart';
import '../../domain/models/nutrient_codes.dart';
import '../../domain/models/nutrition_summary.dart';
import '../nutrient_amount_formatter.dart';
import '../nutrient_labels.dart';

const _summaryHeaderStackBreakpoint = 360.0;

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
    final calories = summary.nutrient(NutrientCodes.calories);
    final progress = ((calories?.amount ?? 0) / calorieGoal).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Text(
                  '每日營養摘要',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                );
                final amount = Text(
                  '${formatNutrientAmount(calories)} / '
                  '${calorieGoal.toStringAsFixed(0)} kcal',
                );
                if (constraints.maxWidth < _summaryHeaderStackBreakpoint) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, amount],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    amount,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.small),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: AppSpacing.large),
            Wrap(
              spacing: AppSpacing.extraLarge,
              runSpacing: AppSpacing.medium,
              children: [
                for (final code in const [
                  NutrientCodes.protein,
                  NutrientCodes.fat,
                  NutrientCodes.carbohydrates,
                ])
                  _NutritionMetric(
                    nutrient: summary.nutrient(code),
                    fallbackLabel: fallbackNutrientLabel(code),
                  ),
              ],
            ),
            if (summary.mealTypes.isNotEmpty) ...[
              const Divider(height: AppSpacing.extraLarge),
              Text(
                '餐別明細',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.small),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  for (final meal in summary.mealTypes)
                    _MealTypeDetails(
                      label:
                          MealType.fromCode(meal.mealTypeCode)?.label ??
                          meal.mealTypeCode,
                      totals: meal.totals,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealTypeDetails extends StatelessWidget {
  const _MealTypeDetails({required this.label, required this.totals});

  final String label;
  final List<NutrientAmount> totals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          for (final code in NutrientCodes.core) Text(_mealNutrientText(code)),
        ],
      ),
    );
  }

  String _mealNutrientText(String code) {
    final nutrient = totals.nutrientByCode(code);
    return '${nutrient?.displayName ?? fallbackNutrientLabel(code)} '
        '${formatNutrientAmount(nutrient)}';
  }
}

class _NutritionMetric extends StatelessWidget {
  const _NutritionMetric({required this.nutrient, required this.fallbackLabel});

  final NutrientAmount? nutrient;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nutrient?.displayName ?? fallbackLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          formatNutrientAmount(nutrient),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
