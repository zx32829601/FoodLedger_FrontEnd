import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/food.dart';
import '../../domain/models/meal_type.dart';
import '../providers/record_providers.dart';

class AddRecordDialog extends ConsumerStatefulWidget {
  const AddRecordDialog({super.key});

  @override
  ConsumerState<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends ConsumerState<AddRecordDialog> {
  final _quantityController = TextEditingController(text: '100');
  String _query = '';
  Food? _selectedFood;
  MealType _mealType = MealType.breakfast;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodSearchProvider(_query));

    return AlertDialog(
      title: const Text('新增飲食紀錄'),
      content: SizedBox(
        width: 560,
        height: 470,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('food-search-field'),
              decoration: const InputDecoration(
                labelText: '搜尋食物',
                hintText: '例如：雞胸肉、白飯',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: foods.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('找不到符合條件的食物'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final food = items[index];
                      final isSelected = food.id == _selectedFood?.id;

                      return ListTile(
                        key: Key('food-option-${food.id}'),
                        selected: isSelected,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        title: Text(food.name),
                        subtitle: Text(
                          '${food.nutritionPer100Grams.calories.toStringAsFixed(0)} '
                          'kcal / 100 克',
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle)
                            : null,
                        onTap: () => setState(() => _selectedFood = food),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    const Center(child: Text('食物資料暫時無法載入')),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('record-quantity-field'),
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '份量（克）',
                      suffixText: 'g',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: DropdownButtonFormField<MealType>(
                    initialValue: _mealType,
                    decoration: const InputDecoration(labelText: '餐別'),
                    items: [
                      for (final mealType in MealType.values)
                        DropdownMenuItem(
                          value: mealType,
                          child: Text(mealType.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _mealType = value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('save-record-button'),
          onPressed: _isSubmitting ? null : _save,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('儲存'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final quantity = double.tryParse(_quantityController.text.trim());
    if (_selectedFood == null || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇食物並輸入有效份量')));
      return;
    }

    setState(() => _isSubmitting = true);
    await ref
        .read(dailyRecordsProvider.notifier)
        .addRecord(
          food: _selectedFood!,
          quantityGrams: quantity,
          mealType: _mealType,
        );

    if (!mounted) return;
    final result = ref.read(dailyRecordsProvider);
    if (result.hasError) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('新增失敗，請稍後再試')));
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('飲食紀錄已新增')));
  }
}
