import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/localization/iana_local_date.dart';
import '../../../../core/localization/localization_providers.dart';
import '../../domain/models/daily_record.dart';
import '../../domain/models/food.dart';
import '../../domain/models/food_nutrition_preview.dart';
import '../../domain/models/meal_type_option.dart';
import '../providers/record_providers.dart';

class AddRecordDialog extends ConsumerStatefulWidget {
  const AddRecordDialog({
    this.initialRecord,
    this.recordDate,
    this.initialFood,
    this.initialQuantity,
    this.lockFoodAndQuantity = false,
    this.showSuccessDialog = true,
    this.onFoodUnavailable,
    this.onSaved,
    super.key,
  });

  final DailyRecord? initialRecord;
  final DateTime? recordDate;
  final Food? initialFood;
  final double? initialQuantity;
  final bool lockFoodAndQuantity;
  final bool showSuccessDialog;
  final VoidCallback? onFoodUnavailable;
  final VoidCallback? onSaved;

  @override
  ConsumerState<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends ConsumerState<AddRecordDialog> {
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;
  late DateTime _consumedAt;
  String _query = '';
  int _page = 1;
  Food? _selectedFood;
  String? _mealTypeCode;
  String? _mealTypeError;
  bool _mealTypeInitialized = false;
  bool _isSubmitting = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedFood = widget.initialRecord?.food ?? widget.initialFood;
    _quantityController = TextEditingController(
      text:
          (widget.initialRecord?.quantityGrams ?? widget.initialQuantity ?? 100)
              .toString(),
    );
    _noteController = TextEditingController(text: widget.initialRecord?.note);
    final timeZone = ref.read(nutritionTimeZoneProvider);
    if (widget.initialRecord case final record?) {
      _consumedAt = localDateTimeFromInstant(record.consumedAt, timeZone);
      _mealTypeCode = record.mealTypeCode;
      _mealTypeInitialized = true;
    } else {
      final now = localDateTimeFromInstant(DateTime.now(), timeZone);
      final date = widget.recordDate;
      _consumedAt = date == null
          ? now
          : localDateTimeInTimeZone(
              date,
              now.hour,
              timeZone,
              minute: now.minute,
            );
    }
    ref.listenManual(mealTypeOptionsProvider, (_, next) {
      final options = next.value;
      if (!mounted ||
          _mealTypeInitialized ||
          options == null ||
          options.isEmpty) {
        return;
      }
      setState(() {
        _mealTypeCode = _suggestMealType(options, _consumedAt.hour);
        _mealTypeInitialized = true;
      });
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
    final mealTypes = ref.watch(mealTypeOptionsProvider);
    final canChooseFood =
        widget.initialRecord == null && !widget.lockFoodAndQuantity;
    final foods = canChooseFood
        ? ref.watch(foodSearchProvider((query: _query, page: _page)))
        : null;
    return AlertDialog(
      title: Text(widget.initialRecord == null ? '新增飲食紀錄' : '編輯飲食紀錄'),
      content: SizedBox(
        width: 580,
        height: 610,
        child: ListView(
          children: [
            if (canChooseFood) ...[
              TextField(
                key: const Key('food-search-field'),
                decoration: const InputDecoration(
                  labelText: '搜尋食物',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () {
                    if (mounted) {
                      setState(() {
                        _query = value;
                        _page = 1;
                      });
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: foods!.when(
                  data: (result) => ListView.builder(
                    itemCount: result.items.length,
                    itemBuilder: (context, index) {
                      final item = result.items[index];
                      return ListTile(
                        key: Key('food-option-${item.id}'),
                        selected: item.id == _selectedFood?.id,
                        title: Text(item.name),
                        subtitle: item.englishName == null
                            ? null
                            : Text(item.englishName!),
                        onTap: () async {
                          final food = await ref.read(
                            foodDetailProvider(item.id).future,
                          );
                          if (mounted) setState(() => _selectedFood = food);
                        },
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(child: Text('食物資料載入失敗')),
                ),
              ),
            ] else
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_selectedFood?.name ?? '尚未選擇食物'),
                subtitle: const Text('食物與份量請回上一頁修改'),
              ),
            TextField(
              key: const Key('record-quantity-field'),
              controller: _quantityController,
              readOnly: widget.lockFoodAndQuantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '食用份量',
                hintText: '例如 150',
                suffixText: '克',
                helperText: '請輸入實際食用重量，營養數值會依此克數換算。',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('record-date-field'),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_consumedAt.year}/${_consumedAt.month}/${_consumedAt.day}',
                    ),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('record-time-field'),
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      TimeOfDay.fromDateTime(_consumedAt).format(context),
                    ),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            mealTypes.when(
              data: (options) => DropdownButtonFormField<String>(
                key: const Key('record-meal-type-field'),
                initialValue: options.any((item) => item.code == _mealTypeCode)
                    ? _mealTypeCode
                    : null,
                decoration: InputDecoration(
                  labelText: '餐別',
                  errorText:
                      _mealTypeError ??
                      (widget.initialRecord != null &&
                              _mealTypeCode != null &&
                              !options.any((item) => item.code == _mealTypeCode)
                          ? '餐別已更新，請重新選擇'
                          : null),
                ),
                items: [
                  for (final option in options)
                    DropdownMenuItem(
                      value: option.code,
                      child: Text(option.displayName),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _mealTypeCode = value;
                  _mealTypeError = null;
                }),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => OutlinedButton(
                onPressed: () => ref.invalidate(mealTypeOptionsProvider),
                child: const Text('重新載入餐別'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('record-note-field'),
              controller: _noteController,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '備註'),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _consumedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final timeZone = ref.read(nutritionTimeZoneProvider);
    setState(
      () => _consumedAt = localDateTimeInTimeZone(
        picked,
        _consumedAt.hour,
        timeZone,
        minute: _consumedAt.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_consumedAt),
    );
    if (picked == null) return;
    final timeZone = ref.read(nutritionTimeZoneProvider);
    setState(
      () => _consumedAt = localDateTimeInTimeZone(
        _consumedAt,
        picked.hour,
        timeZone,
        minute: picked.minute,
      ),
    );
  }

  Future<void> _save() async {
    final quantity = FoodNutritionPreview.parseQuantity(
      _quantityController.text,
    );
    final food = _selectedFood;
    final options =
        ref.read(mealTypeOptionsProvider).value ?? const <MealTypeOption>[];
    final mealType = options.any((item) => item.code == _mealTypeCode)
        ? _mealTypeCode
        : null;
    if (food == null || quantity == null || mealType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請確認食物、份量與餐別')));
      return;
    }
    if (_consumedAt.toUtc().isAfter(DateTime.now().toUtc())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('食用時間不可晚於現在')));
      return;
    }
    setState(() => _isSubmitting = true);
    Object? error;
    try {
      if (widget.initialRecord == null) {
        await ref
            .read(dailyRecordsProvider.notifier)
            .addRecord(
              food: food,
              quantityGrams: quantity,
              consumedAt: _consumedAt,
              mealTypeCode: mealType,
              note: _noteController.text,
            );
      } else {
        await ref
            .read(dailyRecordsProvider.notifier)
            .updateRecord(
              record: widget.initialRecord!,
              food: food,
              quantityGrams: quantity,
              consumedAt: _consumedAt,
              mealTypeCode: mealType,
              note: _noteController.text,
            );
        error = ref.read(dailyRecordsProvider).error;
      }
    } on Object catch (caught) {
      error = caught;
    }
    if (!mounted) return;
    if (_isInvalidMealType(error)) {
      ref.invalidate(mealTypeOptionsProvider);
      setState(() {
        _isSubmitting = false;
        _mealTypeCode = null;
        _mealTypeError = '餐別已更新，請重新選擇';
      });
      return;
    }
    if (error is ApiException && error.statusCode == 404) {
      Navigator.pop(context);
      widget.onFoodUnavailable?.call();
      return;
    }
    if (error != null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('儲存失敗，請重試')));
      return;
    }
    widget.onSaved?.call();
    if (widget.initialRecord != null || !widget.showSuccessDialog) {
      Navigator.pop(context, _consumedAt);
      return;
    }
    setState(() => _isSubmitting = false);

    final viewRecords = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('飲食紀錄已新增'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('繼續新增'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('查看飲食紀錄'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final router = GoRouter.of(context);
    Navigator.pop(context, _consumedAt);
    if (viewRecords == true) {
      ref
          .read(selectedDateProvider.notifier)
          .select(
            DateTime(_consumedAt.year, _consumedAt.month, _consumedAt.day),
          );
      ref.invalidate(dailyRecordsProvider);
      ref.invalidate(nutritionSummaryProvider);
      router.go(AppRoutes.records);
    }
  }

  static String _suggestMealType(List<MealTypeOption> options, int hour) {
    final preferred = hour >= 5 && hour < 11
        ? 'Breakfast'
        : hour >= 11 && hour < 16
        ? 'Lunch'
        : hour >= 16 && hour < 22
        ? 'Dinner'
        : 'Snack';
    return options
            .where((item) => item.code.toLowerCase() == preferred.toLowerCase())
            .firstOrNull
            ?.code ??
        options.first.code;
  }

  static bool _isInvalidMealType(Object? error) {
    if (error is! ApiException) return false;
    if (error.code == 'DailyRecord.InvalidMealType') return true;
    return error.fieldErrors.values
        .expand((items) => items)
        .any((item) => item.code == 'DailyRecord.InvalidMealType');
  }
}
