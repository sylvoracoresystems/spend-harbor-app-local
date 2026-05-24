import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// 弹出"确认 / 取消"二选一对话框。返回值：用户点 confirm 时 true，其余情况 false。
///
/// - [confirmText] 为空时使用 `txDelete` 文案（删除是最常见用例）。
/// - [cancelText] 为空时使用 `txCancel`。
/// - [destructive] 仅作语义标记；目前样式不变，预留未来需要红色 confirm 按钮时使用。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmText,
  String? cancelText,
  bool destructive = true,
}) async {
  final l = AppL10n.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelText ?? l.txCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmText ?? l.txDelete),
        ),
      ],
    ),
  );
  return result == true;
}
