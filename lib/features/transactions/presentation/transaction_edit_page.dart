import 'package:flutter/material.dart';

import 'transaction_form.dart';

class TransactionEditPage extends StatelessWidget {
  const TransactionEditPage({super.key, this.id});

  /// 为 null 时为新建，非 null 时为编辑。
  final String? id;

  @override
  Widget build(BuildContext context) {
    return TransactionForm(editId: id);
  }
}
