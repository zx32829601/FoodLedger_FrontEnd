import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/localization/localization_providers.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../authentication/presentation/providers/auth_providers.dart';
import '../../records/data/api_food_repository.dart';
import '../../records/domain/models/food.dart';
import '../../records/domain/repositories/food_repository.dart';
import '../data/admin_food_api.dart';
import '../domain/admin_food.dart';
import '../domain/admin_food_repository.dart';
import '../domain/nutrient_definition.dart';

final adminFoodRepositoryProvider = Provider<AdminFoodRepository>((ref) {
  return ApiAdminFoodRepository(ref.watch(apiClientProvider).dio);
});

final adminFoodSearchRepositoryProvider = Provider<FoodRepository>((ref) {
  return ApiFoodRepository(ref.watch(apiClientProvider).dio);
});

final adminFoodSearchProvider = FutureProvider.family<List<Food>, String>((
  ref,
  query,
) {
  return ref
      .watch(adminFoodSearchRepositoryProvider)
      .searchFoods(
        query: query,
        langCode: ref.watch(nutritionLangCodeProvider),
      );
});

final adminNutrientsProvider = FutureProvider<List<NutrientDefinition>>((ref) {
  return ref
      .watch(adminFoodRepositoryProvider)
      .getNutrients(langCode: ref.watch(nutritionLangCodeProvider));
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
    final foods = ref.watch(adminFoodSearchProvider(_query));
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
                  key: const Key('create-food-button'),
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
              child: foods.when(
                data: (items) => items.isEmpty
                    ? const Center(child: Text('目前沒有符合條件的食物'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final food = items[index];
                          return ListTile(
                            title: Text(food.name),
                            subtitle: Text(food.code),
                            onTap: () => _openEditor(food: food),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: Key('edit-food-${food.id}'),
                                  tooltip: '編輯',
                                  onPressed: () => _openEditor(food: food),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  key: Key('delete-food-${food.id}'),
                                  tooltip: '刪除',
                                  color: Theme.of(context).colorScheme.error,
                                  onPressed: () => _delete(food),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
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
      ref.invalidate(adminFoodSearchProvider(_query));
    }
  }

  Future<void> _delete(Food food) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: '刪除食物',
      message: '確定刪除「${food.name}」？已有飲食紀錄的食物無法刪除；刪除後也無法復原。',
      confirmLabel: '刪除',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(adminFoodRepositoryProvider).delete(food.id);
      ref.invalidate(adminFoodSearchProvider(_query));
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
    final langCode = ref.read(nutritionLangCodeProvider);
    _code = TextEditingController(text: widget.initial?.code);
    _name = TextEditingController(
      text:
          widget.initial?.translations[langCode]?.displayName ??
          widget.initial?.displayName,
    );
    _nutrients = {};
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
    final nutrientDefinitions = ref.watch(adminNutrientsProvider);
    return AlertDialog(
      title: Text(widget.initial == null ? '建立食物' : '編輯食物'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                key: const Key('food-code-field'),
                controller: _code,
                decoration: const InputDecoration(labelText: '食物代碼'),
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                key: const Key('food-name-field'),
                controller: _name,
                decoration: const InputDecoration(labelText: '繁體中文名稱'),
              ),
              const SizedBox(height: AppSpacing.medium),
              ...nutrientDefinitions.when(
                data: (items) => [
                  for (final nutrient in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.small),
                      child: TextField(
                        key: Key('nutrient-${nutrient.code}'),
                        controller: _nutrientController(nutrient.code),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              '${nutrient.displayName}'
                              '（${nutrient.unitCode}／每 100 克）',
                        ),
                      ),
                    ),
                ],
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.medium),
                    child: CircularProgressIndicator(),
                  ),
                ],
                error: (error, stackTrace) => [const Text('營養素目錄載入失敗，請稍後重試。')],
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
          key: const Key('save-food-button'),
          onPressed: _saving || !nutrientDefinitions.hasValue ? null : _save,
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

  TextEditingController _nutrientController(String code) {
    return _nutrients.putIfAbsent(
      code,
      () => TextEditingController(
        text: widget.initial?.nutrients[code]?.toString() ?? '',
      ),
    );
  }

  Future<void> _save() async {
    final nutrientValues = <String, double>{};
    final definitions = ref.read(adminNutrientsProvider).value;
    if (definitions == null) return;
    for (final definition in definitions) {
      final rawValue = _nutrientController(definition.code).text.trim();
      if (rawValue.isEmpty) continue;
      final value = double.tryParse(rawValue);
      if (value == null || value < 0) return;
      nutrientValues[definition.code] = value;
    }
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      final translations = Map<String, AdminFoodTranslation>.from(
        widget.initial?.translations ?? const {},
      );
      final langCode = ref.read(nutritionLangCodeProvider);
      translations[langCode] = AdminFoodTranslation(
        displayName: _name.text,
        description: translations[langCode]?.description ?? '',
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
