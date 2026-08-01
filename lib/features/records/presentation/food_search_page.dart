import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import 'providers/record_providers.dart';

class FoodSearchPage extends ConsumerStatefulWidget {
  const FoodSearchPage({super.key});
  @override
  ConsumerState<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends ConsumerState<FoodSearchPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  int _page = 1;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _search(String value) {
    setState(() {
      _query = value.trim();
      _page = 1;
    });
    _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final request = (query: _query, page: _page);
    final result = ref.watch(foodSearchProvider(request));
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
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: '食物名稱',
                hintText: '例如 雞胸肉',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                _debounce?.cancel();
                _search(value);
              },
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) _search(value);
                });
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: result.when(
                data: (data) => data.items.isEmpty
                    ? const Center(child: Text('找不到符合的食物'))
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: data.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final food = data.items[index];
                          return ListTile(
                            key: Key('food-search-item-${food.id}'),
                            title: Text(food.name),
                            subtitle: food.englishName == null
                                ? null
                                : Text(food.englishName!),
                            trailing: Text(
                              food.caloriesPer100Grams == null
                                  ? '— kcal / 100 克'
                                  : '${_trim(food.caloriesPer100Grams!)} kcal / 100 克',
                            ),
                            onTap: () =>
                                context.push(AppRoutes.foodDetail(food.id)),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(foodSearchProvider(request)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新載入'),
                  ),
                ),
              ),
            ),
            result.maybeWhen(
              data: (data) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1 ? () => setState(() => _page--) : null,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '上一頁',
                  ),
                  DropdownButton<int>(
                    value: _page.clamp(1, data.totalPages),
                    items: [
                      for (var page = 1; page <= data.totalPages; page++)
                        DropdownMenuItem(value: page, child: Text('第 $page 頁')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _page = value);
                    },
                  ),
                  IconButton(
                    onPressed: _page < data.totalPages
                        ? () => setState(() => _page++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '下一頁',
                  ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  static String _trim(double value) =>
      value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}
