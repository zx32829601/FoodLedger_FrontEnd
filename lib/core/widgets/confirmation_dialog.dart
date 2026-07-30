import 'package:flutter/material.dart';

/// 顯示共用確認 Dialog，讓呼叫端自行提供可在地化的文案。
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '確認',
  String cancelLabel = '取消',
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            key: const Key('confirmation-cancel-button'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            key: const Key('confirmation-confirm-button'),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
