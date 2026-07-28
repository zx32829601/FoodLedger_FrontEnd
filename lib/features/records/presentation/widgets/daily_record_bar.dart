import 'package:flutter/material.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/daily_record.dart';
import '../../domain/models/nutrient_codes.dart';
import '../nutrient_amount_formatter.dart';

/// 以獨立圓角 Bar 呈現一筆飲食紀錄。
class DailyRecordBar extends StatelessWidget {
  const DailyRecordBar({
    required this.record,
    this.showMealType = false,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  final DailyRecord record;
  final bool showMealType;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final details = [
      if (showMealType) record.mealType.label,
      '${record.quantityGrams.toStringAsFixed(0)} 克',
    ].join(' ・ ');

    return Material(
      key: Key('daily-record-bar-${record.id}'),
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mediumBorderRadius,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.medium,
            top: AppSpacing.small,
            right: onDelete == null ? AppSpacing.medium : AppSpacing.small,
            bottom: AppSpacing.small,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Text(record.food.name.characters.first),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.extraSmall),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: AppRadius.smallBorderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                    vertical: AppSpacing.extraSmall,
                  ),
                  child: Text(
                    formatNutrientAmount(
                      record.nutrient(NutrientCodes.calories),
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: AppSpacing.extraSmall),
                IconButton(
                  key: Key('delete-record-${record.id}'),
                  tooltip: '刪除 ${record.food.name}',
                  color: colorScheme.error,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
              if (onEdit != null)
                IconButton(
                  key: Key('edit-record-${record.id}'),
                  tooltip: '編輯 ${record.food.name}',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
