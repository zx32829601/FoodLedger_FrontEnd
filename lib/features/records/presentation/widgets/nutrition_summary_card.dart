import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/nutrient_codes.dart';
import '../../domain/models/nutrition_summary.dart';
import '../nutrient_amount_formatter.dart';
import '../nutrient_labels.dart';

const _summaryHeaderStackBreakpoint = 360.0;

class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard({
    required this.summary,
    this.mealTypeLabels = const {},
    this.calorieGoal = 2000,
    super.key,
  });

  final NutritionSummary summary;
  final Map<String, String> mealTypeLabels;
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
              Column(
                children: [
                  for (final meal in summary.mealTypes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.small),
                      child: _MealTypeBanner(
                        mealTypeCode: meal.mealTypeCode,
                        label:
                            mealTypeLabels[meal.mealTypeCode] ??
                            meal.mealTypeCode,
                        totals: meal.totals,
                      ),
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

class _MealTypeBanner extends StatelessWidget {
  const _MealTypeBanner({
    required this.mealTypeCode,
    required this.label,
    required this.totals,
  });

  final String mealTypeCode;
  final String label;
  final List<NutrientAmount> totals;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('meal-banner-$mealTypeCode'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.extraSmall),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.small,
            children: [
              for (final code in NutrientCodes.core)
                _NutritionMetric(
                  nutrient: totals.nutrientByCode(code),
                  fallbackLabel: fallbackNutrientLabel(code),
                ),
            ],
          ),
        ],
      ),
    );
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
