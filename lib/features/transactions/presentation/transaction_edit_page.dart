import 'package:flutter/material.dart';

import 'transaction_form.dart';

/// 交易新建/编辑路由入口：仅作为 TransactionForm 的 thin wrapper。
class TransactionEditPage extends StatelessWidget {
  const TransactionEditPage({super.key, this.id});

  /// 为 null 时为新建，非 null 时为编辑。
  final String? id;

  @override
  Widget build(BuildContext context) {
    return TransactionForm(editId: id);
  }
}
