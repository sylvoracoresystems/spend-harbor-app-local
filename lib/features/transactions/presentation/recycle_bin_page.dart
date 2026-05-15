import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/recycle_bin_controller.dart';

class RecycleBinPage extends ConsumerWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(trashedTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.recycleBinTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x6),
                child: Text(
                  l.recycleBinEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.sm.copyWith(color: c.textMuted),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.x3),
            itemCount: rows.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.x2),
            itemBuilder: (context, i) => _TrashRow(tx: rows[i]),
          );
        },
      ),
    );
  }
}

class _TrashRow extends ConsumerWidget {
  const _TrashRow({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final cat = categories.where((x) => x.id == tx.categoryId).firstOrNull;
    final isExpense = tx.type == TransactionType.expense;
    final amountColor = isExpense ? c.expense : c.income;
    final sign = isExpense ? '-' : '+';
    final symbol = Currency.byCode(tx.currency).symbol;
    final amount =
        '$sign$symbol${(tx.amountCents / 100).toStringAsFixed(2)}';
    final left = tx.deletedAt == null ? 30 : daysLeft(tx.deletedAt!);
    final catLabel = cat == null
        ? '—'
        : (resolveDefaultName(AppL10n.of(context), cat.nameKey) ?? cat.name);

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
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
                      catLabel,
                      style: AppTypography.sm.copyWith(
                        color: c.actionInk,
                        fontWeight: AppTypography.weightSemibold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${tx.transactedOn} · ${l.recycleBinDaysLeft(left)}',
                        style: AppTypography.xs.copyWith(color: c.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: AppTypography.sm
                    .merge(AppTypography.mono)
                    .copyWith(
                      color: amountColor,
                      fontWeight: AppTypography.weightSemibold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.rotateCcw, size: 16),
                  onPressed: () => ref
                      .read(recycleBinControllerProvider)
                      .restore(tx.id),
                  label: Text(l.recycleBinRestore),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  style: OutlinedButton.styleFrom(foregroundColor: c.expense),
                  onPressed: () => _confirmPurge(context, ref, tx.id),
                  label: Text(l.recycleBinPurge),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmPurge(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final l = AppL10n.of(context);
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.recycleBinPurgeConfirmTitle),
      content: Text(l.recycleBinPurgeConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.txCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.recycleBinPurge),
        ),
      ],
    ),
  );
  if (yes == true) {
    await ref.read(recycleBinControllerProvider).purge(id);
  }
}
