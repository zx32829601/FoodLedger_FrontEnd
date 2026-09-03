import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/localization/iana_local_date.dart';
import '../../../core/localization/localization_providers.dart';
import '../domain/models/body_measurement.dart';
import 'providers/body_measurement_providers.dart';

/// 顯示目前登入者的身體量測歷史，並提供新增、編輯、篩選與安全刪除。
class BodyMeasurementsPage extends ConsumerWidget {
  const BodyMeasurementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(bodyMeasurementProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('身體量測紀錄')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-body-measurement-button'),
        onPressed: () => _showMeasurementDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新增量測'),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(error: error),
        data: (value) => _HistoryBody(value: value),
      ),
    );
  }
}

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({required this.value});

  final BodyMeasurementHistoryState value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(bodyMeasurementProvider.notifier).reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.large,
          AppSpacing.large,
          AppSpacing.large,
          96,
        ),
        children: [
          _DateRangeFilter(value: value),
          const SizedBox(height: AppSpacing.medium),
          if (value.items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.large),
                child: Column(
                  children: [
                    Icon(Icons.monitor_weight_outlined, size: 48),
                    SizedBox(height: AppSpacing.small),
                    Text('目前沒有符合條件的量測紀錄'),
                  ],
                ),
              ),
            )
          else
            for (final measurement in value.items) ...[
              _MeasurementCard(measurement: measurement),
              const SizedBox(height: AppSpacing.small),
            ],
          if (value.hasNextPage) ...[
            const SizedBox(height: AppSpacing.small),
            OutlinedButton.icon(
              key: const Key('load-more-body-measurements-button'),
              onPressed: () =>
                  ref.read(bodyMeasurementProvider.notifier).loadNextPage(),
              icon: const Icon(Icons.expand_more),
              label: const Text('載入更多'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateRangeFilter extends ConsumerWidget {
  const _DateRangeFilter({required this.value});

  final BodyMeasurementHistoryState value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilter = value.fromDate != null || value.toDate != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              hasFilter
                  ? '${_date(value.fromDate) ?? '最早'} ～ ${_date(value.toDate) ?? '最新'}'
                  : '目前顯示全部量測紀錄',
            ),
            OutlinedButton.icon(
              key: const Key('filter-body-measurements-button'),
              onPressed: () => _pickRange(context, ref),
              icon: const Icon(Icons.date_range_outlined),
              label: const Text('日期篩選'),
            ),
            if (hasFilter)
              TextButton(
                key: const Key('clear-body-measurements-filter-button'),
                onPressed: () =>
                    ref.read(bodyMeasurementProvider.notifier).clearDateRange(),
                child: const Text('清除'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: value.fromDate != null && value.toDate != null
          ? DateTimeRange(start: value.fromDate!, end: value.toDate!)
          : null,
    );
    if (selected != null) {
      await ref
          .read(bodyMeasurementProvider.notifier)
          .applyDateRange(selected.start, selected.end);
    }
  }
}

class _MeasurementCard extends ConsumerWidget {
  const _MeasurementCard({required this.measurement});

  final BodyMeasurement measurement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeZone = ref.watch(nutritionTimeZoneProvider);
    final measuredAt = localDateTimeFromInstant(
      measurement.measuredAt,
      timeZone,
    );
    return Card(
      key: Key('body-measurement-${measurement.measurementId}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_weight_outlined),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    '${_number(measurement.weightInKilograms)} kg',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(_dateTime(measuredAt)),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              '體脂：${_optional(measurement.bodyFatPercentage, '%')}　'
              '肌肉量：${_optional(measurement.muscleMassInKilograms, 'kg')}',
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: Key(
                    'edit-body-measurement-${measurement.measurementId}',
                  ),
                  onPressed: () =>
                      _showMeasurementDialog(context, ref, measurement),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('編輯'),
                ),
                const SizedBox(width: AppSpacing.small),
                FilledButton.icon(
                  key: Key(
                    'delete-body-measurement-${measurement.measurementId}',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('刪除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      final controller = ref.read(bodyMeasurementProvider.notifier);
      final impact = await controller.getDeletionImpact(
        measurement.measurementId,
      );
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('刪除量測紀錄'),
          content: Text(
            impact.affectedSnapshotCount == 0
                ? '這筆紀錄目前沒有影響營養目標快照。確定刪除嗎？'
                : '將影響 ${impact.affectedSnapshotCount} 筆營養目標快照'
                      '${impact.affectsCurrentTarget ? '，包含目前使用中的目標' : ''}。確定刪除嗎？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('確認刪除'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await controller.delete(impact);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('量測紀錄已刪除')));
    } on ApiException catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }
}

Future<void> _showMeasurementDialog(
  BuildContext context,
  WidgetRef ref, [
  BodyMeasurement? existing,
]) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _MeasurementDialog(existing: existing),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(existing == null ? '量測紀錄已新增' : '量測紀錄已更新')),
    );
  }
}

class _MeasurementDialog extends ConsumerStatefulWidget {
  const _MeasurementDialog({this.existing});

  final BodyMeasurement? existing;

  @override
  ConsumerState<_MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends ConsumerState<_MeasurementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _bodyFat;
  late final TextEditingController _muscleMass;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
      text: widget.existing == null
          ? ''
          : _number(widget.existing!.weightInKilograms),
    );
    _bodyFat = TextEditingController(
      text: widget.existing?.bodyFatPercentage == null
          ? ''
          : _number(widget.existing!.bodyFatPercentage!),
    );
    _muscleMass = TextEditingController(
      text: widget.existing?.muscleMassInKilograms == null
          ? ''
          : _number(widget.existing!.muscleMassInKilograms!),
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    _muscleMass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '新增身體量測' : '編輯身體量測'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberField(
                key: const Key('measurement-weight-field'),
                controller: _weight,
                label: '體重',
                suffix: 'kg',
                minimum: 20,
                maximum: 400,
                required: true,
              ),
              const SizedBox(height: AppSpacing.medium),
              _numberField(
                key: const Key('measurement-body-fat-field'),
                controller: _bodyFat,
                label: '體脂率（選填）',
                suffix: '%',
                minimum: 1,
                maximum: 75,
              ),
              const SizedBox(height: AppSpacing.medium),
              _numberField(
                key: const Key('measurement-muscle-mass-field'),
                controller: _muscleMass,
                label: '肌肉量（選填）',
                suffix: 'kg',
                minimum: 5,
                maximum: 200,
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
          key: const Key('save-body-measurement-button'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '儲存中…' : '儲存'),
        ),
      ],
    );
  }

  Widget _numberField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String suffix,
    required double minimum,
    required double maximum,
    bool required = false,
  }) => TextFormField(
    key: key,
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: suffix),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return required ? '此欄位為必填' : null;
      final number = double.tryParse(text);
      if (number == null || number < minimum || number > maximum) {
        return '請輸入 $minimum 到 $maximum';
      }
      return RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(text) ? null : '最多可輸入兩位小數';
    },
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final controller = ref.read(bodyMeasurementProvider.notifier);
      final weight = double.parse(_weight.text.trim());
      final bodyFat = double.tryParse(_bodyFat.text.trim());
      final muscleMass = double.tryParse(_muscleMass.text.trim());
      if (widget.existing == null) {
        await controller.create(
          weightInKilograms: weight,
          bodyFatPercentage: bodyFat,
          muscleMassInKilograms: muscleMass,
        );
      } else {
        await controller.updateMeasurement(
          BodyMeasurement(
            measurementId: widget.existing!.measurementId,
            weightInKilograms: weight,
            bodyFatPercentage: bodyFat,
            muscleMassInKilograms: muscleMass,
            measuredAt: widget.existing!.measuredAt,
            version: widget.existing!.version,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(context, error);
      setState(() => _saving = false);
    }
  }
}

class _LoadError extends ConsumerWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiError = error is ApiException ? error as ApiException : null;
    final needsProfile = apiError?.code == 'BodyMeasurement.ProfileRequired';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(apiError?.message ?? '無法載入身體量測紀錄'),
            const SizedBox(height: AppSpacing.medium),
            if (needsProfile)
              FilledButton(
                onPressed: () => context.push(AppRoutes.bodyProfile),
                child: const Text('先建立身體資料'),
              )
            else
              OutlinedButton(
                onPressed: () =>
                    ref.read(bodyMeasurementProvider.notifier).reload(),
                child: const Text('重新載入'),
              ),
          ],
        ),
      ),
    );
  }
}

void _showError(BuildContext context, ApiException error) {
  final message = error.code == 'BodyMeasurement.Conflict'
      ? '資料已被其他操作更新，已重新載入最新內容。'
      : error.fieldErrors.values
                .expand((items) => items)
                .firstOrNull
                ?.message ??
            error.message;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String? _date(DateTime? value) => value == null
    ? null
    : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _dateTime(DateTime value) =>
    '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

String _optional(double? value, String suffix) =>
    value == null ? '未填' : '${_number(value)} $suffix';
