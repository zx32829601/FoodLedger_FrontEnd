import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../domain/models/food.dart';
import '../domain/models/food_nutrition_preview.dart';
import '../domain/models/nutrient_codes.dart';
import '../domain/models/nutrition_summary.dart';
import 'nutrient_amount_formatter.dart';
import 'providers/record_providers.dart';
import 'widgets/add_record_dialog.dart';

class FoodDetailPage extends ConsumerStatefulWidget {
  const FoodDetailPage({required this.foodId, super.key});
  final int foodId;
  @override
  ConsumerState<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends ConsumerState<FoodDetailPage> {
  final _quantityController = TextEditingController(text: '100');
  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_refresh);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_refresh);
    _quantityController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  double? get _quantity {
    return FoodNutritionPreview.parseQuantity(_quantityController.text);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(foodDetailProvider(widget.foodId));
    return Scaffold(
      appBar: AppBar(title: const Text('食物明細')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailError(
          error: error,
          onRetry: () => ref.invalidate(foodDetailProvider(widget.foodId)),
        ),
        data: (food) => _buildDetail(context, food),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Food food) {
    final quantity = _quantity;
    final nutrients = FoodNutritionPreview.calculate(
      food.nutrientsPer100Grams,
      quantity ?? 100,
    );
    final other = nutrients
        .where((item) => !NutrientCodes.core.contains(item.code))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(food.name, style: Theme.of(context).textTheme.headlineMedium),
        if (food.englishName != null)
          Text(
            food.englishName!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        if (food.categories.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final category in food.categories)
                Chip(label: Text(category.displayName)),
            ],
          ),
        if (food.description.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(food.description),
          ),
        const SizedBox(height: 24),
        const Text('營養資料基準：每 100 克'),
        TextField(
          key: const Key('food-detail-quantity'),
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '食用份量',
            hintText: '例如 150',
            suffixText: '克',
            helperText: '請輸入實際食用重量，營養數值會依此克數換算。',
            errorText: quantity == null ? '請輸入 0.1 至 10000 克，最多一位小數' : null,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('熱量', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  formatNutrientAmount(
                    nutrients.nutrientByCode(NutrientCodes.calories),
                  ),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            for (final code in [
              NutrientCodes.protein,
              NutrientCodes.fat,
              NutrientCodes.carbohydrates,
            ])
              Expanded(
                child: _MacroTile(
                  label: _macroLabel(code),
                  value: formatNutrientAmount(nutrients.nutrientByCode(code)),
                ),
              ),
          ],
        ),
        if (other.isNotEmpty)
          ExpansionTile(
            title: Text('詳細營養資料（${other.length}）'),
            children: [
              for (final item in other)
                ListTile(
                  title: Text(item.displayName),
                  trailing: Text(formatNutrientAmount(item)),
                ),
            ],
          ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('food-detail-add-button'),
          onPressed: quantity == null ? null : () => _confirm(food, quantity),
          child: const Text('加入飲食紀錄'),
        ),
      ],
    );
  }

  Future<void> _confirm(Food food, double quantity) async {
    final consumedAt = await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddRecordDialog(
        initialFood: food,
        initialQuantity: quantity,
        lockFoodAndQuantity: true,
        showSuccessDialog: false,
        onFoodUnavailable: () =>
            ref.invalidate(foodDetailProvider(widget.foodId)),
      ),
    );
    if (!mounted || consumedAt == null) return;
    final action = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('飲食紀錄已新增'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('繼續新增'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('查看飲食紀錄'),
          ),
        ],
      ),
    );
    if (action == true && mounted) {
      ref
          .read(selectedDateProvider.notifier)
          .select(DateTime(consumedAt.year, consumedAt.month, consumedAt.day));
      ref.invalidate(dailyRecordsProvider);
      ref.invalidate(nutritionSummaryProvider);
      context.go(AppRoutes.records);
    } else if (action == false && mounted) {
      context.pop();
    }
  }

  static String _macroLabel(String code) => switch (code) {
    NutrientCodes.protein => '蛋白質',
    NutrientCodes.fat => '脂肪',
    _ => '碳水化合物',
  };
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final statusCode = error is ApiException
        ? (error as ApiException).statusCode
        : null;
    if (statusCode == 404) {
      return const Center(child: Text('食物目前無法使用'));
    }
    if (statusCode == 401) {
      return const Center(child: Text('登入狀態已失效'));
    }
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('重新載入'),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Column(children: [Text(label), Text(value)]),
  );
}
