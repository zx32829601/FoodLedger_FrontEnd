import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import 'providers/record_providers.dart';

/// 提供一般使用者獨立瀏覽正式食物搜尋結果的頁面。
class FoodSearchPage extends ConsumerStatefulWidget {
  const FoodSearchPage({super.key});

  @override
  ConsumerState<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends ConsumerState<FoodSearchPage> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodSearchProvider(_query));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('食物查詢', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              key: const Key('food-search-page-field'),
              decoration: const InputDecoration(
                labelText: '食物名稱',
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
              child: _query.trim().isEmpty
                  ? const Center(child: Text('輸入關鍵字開始搜尋食物'))
                  : foods.when(
                      data: (items) => items.isEmpty
                          ? const Center(child: Text('找不到符合條件的食物'))
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final food = items[index];
                                return ListTile(
                                  title: Text(food.name),
                                  subtitle: Text(food.code),
                                  trailing: Text(
                                    '${food.nutritionPer100Grams.calories.toStringAsFixed(0)} kcal',
                                  ),
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => Center(
                        child: FilledButton.icon(
                          onPressed: () =>
                              ref.invalidate(foodSearchProvider(_query)),
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新載入'),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
