import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/placeholder_page.dart';

class TransactionEditPage extends StatelessWidget {
  const TransactionEditPage({super.key, this.id});

  /// 为 null 时为新建，非 null 时为编辑。
  final String? id;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return PlaceholderPage(
      title: id == null ? l.newTransactionTitle : l.editTransactionTitle,
    );
  }
}
