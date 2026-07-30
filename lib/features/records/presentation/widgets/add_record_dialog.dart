import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/api/api_exception.dart';
import '../../domain/models/food.dart';
import '../../domain/models/daily_record.dart';
import '../../domain/models/meal_type_option.dart';
import '../../domain/models/nutrient_codes.dart';
import '../../domain/models/nutrient_unit_codes.dart';
import '../nutrient_amount_formatter.dart';
import '../providers/record_providers.dart';

/// 提供飲食紀錄的食物搜尋、新增與編輯流程。
class AddRecordDialog extends ConsumerStatefulWidget {
  const AddRecordDialog({
    this.initialRecord,
    this.recordDate,
    this.onSaved,
    super.key,
  });

  /// 編輯模式使用的既有紀錄；未提供時為新增模式。
  final DailyRecord? initialRecord;

  /// 新增模式要寫入的本地日期；未提供時使用飲食紀錄頁選取日期。
  final DateTime? recordDate;

  /// 紀錄成功儲存後通知開啟視窗的畫面重新整理。
  final VoidCallback? onSaved;

  @override
  ConsumerState<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends ConsumerState<AddRecordDialog> {
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;
  String _query = '';
  Food? _selectedFood;
  String? _mealTypeCode;
  String? _mealTypeError;
  bool _requiresMealTypeReselection = false;
  bool _isSubmitting = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.initialRecord?.quantityGrams.toString() ?? '100',
    );
    _noteController = TextEditingController(text: widget.initialRecord?.note);
    _selectedFood = widget.initialRecord?.food;
    _mealTypeCode = widget.initialRecord?.mealTypeCode;
    ref.listenManual(mealTypeOptionsProvider, (previous, next) {
      final options = next.value;
      if (!mounted ||
          widget.initialRecord != null ||
          _requiresMealTypeReselection ||
          _mealTypeCode != null ||
          options == null ||
          options.isEmpty) {
        return;
      }
      setState(() => _mealTypeCode = options.first.code);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodSearchProvider(_query));
    final mealTypes = ref.watch(mealTypeOptionsProvider);

    return AlertDialog(
      title: Text(widget.initialRecord == null ? '新增飲食紀錄' : '編輯飲食紀錄'),
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
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) setState(() => _query = value);
                });
              },
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
                          '${formatNutrientAmount(food.nutrientPer100Grams(NutrientCodes.calories))} '
                          '/ 100 克',
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
                      suffixText: NutrientUnitCodes.gram,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: mealTypes.when(
                    data: (options) {
                      final selectedCode = _selectedMealTypeCode(options);
                      final hasStaleInitialValue =
                          widget.initialRecord != null &&
                          _mealTypeCode != null &&
                          selectedCode == null;
                      return DropdownButtonFormField<String>(
                        key: const Key('record-meal-type-field'),
                        initialValue: selectedCode,
                        decoration: InputDecoration(
                          labelText: '餐別',
                          errorText:
                              _mealTypeError ??
                              (hasStaleInitialValue ? '餐別已更新，請重新選擇' : null),
                        ),
                        items: [
                          for (final option in options)
                            DropdownMenuItem(
                              value: option.code,
                              child: Text(option.displayName),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _mealTypeCode = value;
                            _mealTypeError = null;
                            _requiresMealTypeReselection = false;
                          });
                        },
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, stackTrace) => OutlinedButton.icon(
                      onPressed: () => ref.invalidate(mealTypeOptionsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重試載入餐別'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              key: const Key('record-note-field'),
              controller: _noteController,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '備註',
                hintText: '例如：公司午餐、少油',
              ),
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
    final mealTypeCode = _selectedMealTypeCode(
      ref.read(mealTypeOptionsProvider).value ?? const [],
    );
    if (_selectedFood == null ||
        quantity == null ||
        quantity <= 0 ||
        mealTypeCode == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇食物並輸入有效份量')));
      return;
    }

    setState(() => _isSubmitting = true);
    Object? mutationError;
    try {
      if (widget.initialRecord == null) {
        await ref
            .read(dailyRecordsProvider.notifier)
            .addRecord(
              food: _selectedFood!,
              quantityGrams: quantity,
              mealTypeCode: mealTypeCode,
              note: _noteController.text,
              recordDate: widget.recordDate,
            );
      } else {
        await ref
            .read(dailyRecordsProvider.notifier)
            .updateRecord(
              record: widget.initialRecord!,
              food: _selectedFood!,
              quantityGrams: quantity,
              mealTypeCode: mealTypeCode,
              note: _noteController.text,
            );
        mutationError = ref.read(dailyRecordsProvider).error;
      }
    } on Object catch (error) {
      mutationError = error;
    }

    if (!mounted) return;
    if (_isInvalidMealType(mutationError)) {
      ref.invalidate(mealTypeOptionsProvider);
      setState(() {
        _isSubmitting = false;
        _mealTypeCode = null;
        _mealTypeError = '餐別已更新，請重新選擇';
        _requiresMealTypeReselection = true;
      });
      return;
    }
    if (mutationError != null) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialRecord == null ? '新增失敗，請稍後再試' : '編輯失敗，請稍後再試',
          ),
        ),
      );
      return;
    }

    widget.onSaved?.call();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.initialRecord == null ? '飲食紀錄已新增' : '飲食紀錄已更新'),
      ),
    );
  }

  String? _selectedMealTypeCode(List<MealTypeOption> options) {
    final currentCode = _mealTypeCode;
    if (currentCode != null &&
        options.any((option) => option.code == currentCode)) {
      return currentCode;
    }
    return null;
  }

  static bool _isInvalidMealType(Object? error) {
    if (error is! ApiException) return false;
    if (error.code == 'DailyRecord.InvalidMealType') return true;
    return error.fieldErrors.values
        .expand((errors) => errors)
        .any((fieldError) => fieldError.code == 'DailyRecord.InvalidMealType');
  }
}
