import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/localization/iana_local_date.dart';
import '../../../core/localization/localization_providers.dart';
import '../domain/models/body_profile.dart';
import '../domain/models/body_profile_option.dart';
import 'providers/body_profile_providers.dart';

/// 建立或修改身體資料的專屬頁面。
class BodyProfilePage extends ConsumerWidget {
  const BodyProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(bodyProfileProvider);
    final options = ref.watch(bodyProfileOptionsProvider);
    final deviceTimeZone = ref.watch(deviceTimeZoneProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('身體資料')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: error is ApiException ? error.message : '無法載入身體資料',
          onRetry: () => ref.read(bodyProfileProvider.notifier).reload(),
        ),
        data: (value) => options.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(
            message: error is ApiException ? error.message : '無法載入選項',
            onRetry: () => ref.invalidate(bodyProfileOptionsProvider),
          ),
          data: (availableOptions) => deviceTimeZone.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _BodyProfileForm(
              key: ValueKey(value?.version ?? 'new'),
              profile: value,
              options: availableOptions,
            ),
            data: (detectedTimeZone) => _BodyProfileForm(
              key: ValueKey(value?.version ?? 'new'),
              profile: value,
              options: availableOptions,
              deviceTimeZone: detectedTimeZone,
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyProfileForm extends ConsumerStatefulWidget {
  const _BodyProfileForm({
    required this.profile,
    required this.options,
    this.deviceTimeZone,
    super.key,
  });

  final BodyProfile? profile;
  final BodyProfileOptions options;
  final String? deviceTimeZone;

  @override
  ConsumerState<_BodyProfileForm> createState() => _BodyProfileFormState();
}

class _BodyProfileFormState extends ConsumerState<_BodyProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime? _birthDate;
  late String _biologicalSexCode;
  late String? _fitnessGoalCode;
  late String? _activityLevelCode;
  late final TextEditingController _birthDateController;
  late final TextEditingController _heightController;
  late final TextEditingController _timeZoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _birthDate = profile?.birthDate;
    _biologicalSexCode = profile?.biologicalSexCode ?? 'MALE';
    _fitnessGoalCode =
        profile?.fitnessGoalCode ??
        widget.options.fitnessGoals.firstOrNull?.code;
    _activityLevelCode =
        profile?.activityLevelCode ??
        widget.options.activityLevels.firstOrNull?.code;
    _birthDateController = TextEditingController(
      text: _birthDate == null ? '' : _dateValue(_birthDate!),
    );
    _heightController = TextEditingController(
      text: profile?.heightInCentimeters.toString() ?? '',
    );
    _timeZoneController = TextEditingController(
      text:
          profile?.timeZone ??
          widget.deviceTimeZone ??
          ref.read(nutritionTimeZoneProvider),
    );
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    _heightController.dispose();
    _timeZoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.profile == null ? '建立身體資料' : '編輯身體資料',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.small),
                const Text('這些資料會完整保存，並用於未來的熱量與營養目標計算。'),
                const SizedBox(height: AppSpacing.large),
                TextFormField(
                  key: const Key('birth-date-field'),
                  readOnly: true,
                  controller: _birthDateController,
                  decoration: const InputDecoration(
                    labelText: '出生日期',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (_) {
                    final birthDate = _birthDate;
                    if (birthDate == null) return '請選擇出生日期';
                    final today = _currentLocalDate();
                    final firstDate = _oldestAllowedBirthDate(today);
                    final lastDate = _yearsBefore(today, 18);
                    return birthDate.isBefore(firstDate) ||
                            birthDate.isAfter(lastDate)
                        ? '年齡必須介於 18 到 120 歲'
                        : null;
                  },
                  onTap: _pickBirthDate,
                ),
                const SizedBox(height: AppSpacing.medium),
                DropdownButtonFormField<String>(
                  key: const Key('biological-sex-field'),
                  initialValue: _biologicalSexCode,
                  decoration: const InputDecoration(labelText: '生理性別'),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('男性')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('女性')),
                  ],
                  onChanged: (value) =>
                      setState(() => _biologicalSexCode = value!),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  key: const Key('height-field'),
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '身高',
                    suffixText: 'cm',
                  ),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';
                    final height = double.tryParse(normalized);
                    if (height == null || height < 100 || height > 250) {
                      return '請輸入 100 到 250 公分';
                    }
                    return RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(normalized)
                        ? null
                        : '身高最多可輸入兩位小數';
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                _OptionField(
                  fieldKey: const Key('fitness-goal-field'),
                  label: '健身目標',
                  value: _fitnessGoalCode,
                  options: widget.options.fitnessGoals,
                  inactiveDisplayName: widget.profile?.fitnessGoalDisplayName,
                  inactiveNote: widget.profile?.fitnessGoalNote,
                  onChanged: (value) =>
                      setState(() => _fitnessGoalCode = value),
                ),
                const SizedBox(height: AppSpacing.medium),
                _OptionField(
                  fieldKey: const Key('activity-level-field'),
                  label: '活動程度',
                  value: _activityLevelCode,
                  options: widget.options.activityLevels,
                  inactiveDisplayName: widget.profile?.activityLevelDisplayName,
                  inactiveNote: widget.profile?.activityLevelNote,
                  onChanged: (value) =>
                      setState(() => _activityLevelCode = value),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  key: const Key('time-zone-field'),
                  controller: _timeZoneController,
                  decoration: const InputDecoration(
                    labelText: 'IANA 時區',
                    hintText: 'Asia/Taipei',
                    helperText: '會先帶入應用程式目前使用的時區，也可自行修改。',
                  ),
                  validator: (value) {
                    final timeZone = value?.trim() ?? '';
                    if (timeZone.isEmpty) return '請輸入 IANA 時區';
                    return tryLocalDateInTimeZone(
                              ref.read(bodyProfileClockProvider)(),
                              timeZone,
                            ) ==
                            null
                        ? '請輸入有效的 IANA 時區'
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.large),
                FilledButton.icon(
                  key: const Key('save-body-profile-button'),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(widget.profile == null ? '建立資料' : '儲存變更'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final today = _currentLocalDate();
    final firstDate = _oldestAllowedBirthDate(today);
    final lastDate = _yearsBefore(today, 18);
    final preferredInitialDate = _birthDate ?? DateTime(today.year - 30);
    final initialDate = preferredInitialDate.isBefore(firstDate)
        ? firstDate
        : preferredInitialDate.isAfter(lastDate)
        ? lastDate
        : preferredInitialDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selected != null) {
      setState(() {
        _birthDate = selected;
        _birthDateController.text = _dateValue(selected);
      });
    }
  }

  DateTime _currentLocalDate() {
    final now = ref.read(bodyProfileClockProvider)();
    final requested = tryLocalDateInTimeZone(
      now,
      _timeZoneController.text.trim(),
    );
    return requested ??
        localDateInTimeZone(now, ref.read(nutritionTimeZoneProvider));
  }

  static DateTime _yearsBefore(DateTime date, int years) {
    final year = date.year - years;
    final lastDayOfMonth = DateTime(year, date.month + 1, 0).day;
    final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
    return DateTime(year, date.month, day);
  }

  static DateTime _oldestAllowedBirthDate(DateTime today) =>
      _yearsBefore(today, 121).add(const Duration(days: 1));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _fitnessGoalCode == null ||
        _activityLevelCode == null) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(bodyProfileProvider.notifier)
          .save(
            BodyProfile(
              birthDate: _birthDate!,
              biologicalSexCode: _biologicalSexCode,
              heightInCentimeters: double.parse(_heightController.text.trim()),
              fitnessGoalCode: _fitnessGoalCode!,
              activityLevelCode: _activityLevelCode!,
              timeZone: _timeZoneController.text.trim(),
              version: widget.profile?.version,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('身體資料已儲存')));
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      final message = error.code == 'BodyProfile.Conflict'
          ? '資料已被其他操作更新，已重新載入最新內容。'
          : error.fieldErrors.values
                    .expand((items) => items)
                    .firstOrNull
                    ?.message ??
                error.message;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  static String _dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.options,
    this.inactiveDisplayName,
    this.inactiveNote,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final String? value;
  final List<BodyProfileOption> options;
  final String? inactiveDisplayName;
  final String? inactiveNote;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = options
        .where((option) => option.code == value)
        .firstOrNull;
    final hasInactiveSelection = value != null && selected == null;
    final inactiveSelectionNote = hasInactiveSelection ? inactiveNote : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: fieldKey,
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: [
            if (hasInactiveSelection)
              DropdownMenuItem(
                value: value,
                child: Text('${inactiveDisplayName ?? value}（已停用）'),
              ),
            for (final option in options)
              DropdownMenuItem(
                value: option.code,
                child: Text(option.displayName),
              ),
          ],
          validator: (current) {
            if (current == null) return '請選擇$label';
            return options.any((option) => option.code == current)
                ? null
                : '此選項已停用，請重新選擇';
          },
          onChanged: onChanged,
        ),
        if (selected?.note case final String note
            when note.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.extraSmall),
          Text(note, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (inactiveSelectionNote case final String note
            when note.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.extraSmall),
          Text(note, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (hasInactiveSelection) ...[
          const SizedBox(height: AppSpacing.extraSmall),
          Text(
            '目前儲存的代碼已停用，請改選一個可用選項。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: AppSpacing.medium),
        OutlinedButton(onPressed: onRetry, child: const Text('重新載入')),
      ],
    ),
  );
}
