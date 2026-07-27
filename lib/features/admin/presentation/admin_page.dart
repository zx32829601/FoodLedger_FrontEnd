import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../authentication/presentation/providers/auth_providers.dart';
import '../../records/domain/models/food.dart';
import '../../records/presentation/providers/record_providers.dart';
import '../data/admin_food_api.dart';
import '../domain/admin_food.dart';
import '../domain/admin_food_repository.dart';

final adminFoodRepositoryProvider = Provider<AdminFoodRepository>((ref) {
  return ApiAdminFoodRepository(ref.watch(apiClientProvider).dio);
});

/// 管理員搜尋、建立、修改與刪除食物的維護頁。
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodSearchProvider(_query));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '管理後台',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('食物資料維護'),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('建立食物'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              decoration: const InputDecoration(
                labelText: '搜尋要維護的食物',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: _query.trim().isEmpty
                  ? const Center(child: Text('輸入食物名稱以載入維護清單'))
                  : foods.when(
                      data: (items) => ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final food = items[index];
                          return ListTile(
                            title: Text(food.name),
                            subtitle: Text(food.code),
                            onTap: () => _openEditor(food: food),
                            trailing: IconButton(
                              tooltip: '刪除',
                              onPressed: () => _delete(food),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        },
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const Center(child: Text('食物資料載入失敗')),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor({Food? food}) async {
    AdminFood? initial;
    if (food != null) {
      try {
        initial = await ref.read(adminFoodRepositoryProvider).get(food.id);
        if (!mounted) return;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('食物詳細資料載入失敗')));
        return;
      }
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _FoodEditorDialog(initial: initial),
    );
    if (saved == true) {
      ref.invalidate(foodSearchProvider(_query));
    }
  }

  Future<void> _delete(Food food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除食物'),
        content: Text('確定刪除「${food.name}」？已有飲食紀錄的食物無法刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminFoodRepositoryProvider).delete(food.id);
      ref.invalidate(foodSearchProvider(_query));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('食物無法刪除，請確認是否已有紀錄使用')));
    }
  }
}

class _FoodEditorDialog extends ConsumerStatefulWidget {
  const _FoodEditorDialog({this.initial});

  final AdminFood? initial;

  @override
  ConsumerState<_FoodEditorDialog> createState() => _FoodEditorDialogState();
}

class _FoodEditorDialogState extends ConsumerState<_FoodEditorDialog> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final Map<String, TextEditingController> _nutrients;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initial?.code);
    _name = TextEditingController(text: widget.initial?.displayName);
    _nutrients = {
      for (final code in ['Calories', 'Protein', 'Carbohydrates', 'Fat'])
        code: TextEditingController(
          text: widget.initial?.nutrients[code]?.toString() ?? '0',
        ),
    };
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    for (final controller in _nutrients.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '建立食物' : '編輯食物'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _code,
                decoration: const InputDecoration(labelText: '食物代碼'),
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: '繁體中文名稱'),
              ),
              const SizedBox(height: AppSpacing.medium),
              for (final entry in _nutrients.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: TextField(
                    controller: entry.value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '${entry.key}（每 100 克）',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
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
    final nutrientValues = <String, double>{};
    for (final entry in _nutrients.entries) {
      final value = double.tryParse(entry.value.text.trim());
      if (value == null || value < 0) return;
      nutrientValues[entry.key] = value;
    }
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      final translations = Map<String, AdminFoodTranslation>.from(
        widget.initial?.translations ?? const {},
      );
      translations['zh-TW'] = AdminFoodTranslation(
        displayName: _name.text,
        description: translations['zh-TW']?.description ?? '',
      );
      await ref
          .read(adminFoodRepositoryProvider)
          .save(
            foodId: widget.initial?.id,
            foodCode: _code.text,
            translations: translations,
            nutrients: nutrientValues,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('儲存失敗，請檢查欄位與營養素設定')));
    }
  }
}
