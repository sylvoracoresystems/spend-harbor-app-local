import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../shared/utils/hex_color.dart';
import '../../../shared/widgets/tag_pill.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/transactions_list_controller.dart';

/// 交易列表行：左侧分类圆形图标 + 分类名 / tag / 备注，右侧金额 / 来源。
///
/// [enableSelection] = true 时长按 + 单击会触发 [selectionControllerProvider]；
/// Dashboard 的 Recent 列表传 false。
class TransactionListRow extends ConsumerWidget {
  const TransactionListRow({
    super.key,
    required this.tx,
    this.enableSelection = false,
  });

  final Transaction tx;
  final bool enableSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final categoriesById = ref.watch(categoriesByIdProvider);
    final sourcesById = ref.watch(sourcesByIdProvider);
    final tagsById = ref.watch(tagsByIdProvider);
    final tagsByTx = ref.watch(tagsForCurrentListProvider).valueOrNull ??
        const <String, List<String>>{};
    final cat = categoriesById[tx.categoryId];
    final src = sourcesById[tx.sourceId];
    final txTagIds = tagsByTx[tx.id] ?? const <String>[];
    final txTags = [
      for (final id in txTagIds)
        if (tagsById[id] case final t?) t,
    ];

    final isExpense = tx.type == TransactionType.expense;
    final amountColor = isExpense ? c.expense : c.income;
    final symbol = Currency.byCode(tx.currency).symbol;
    final amountBody =
        '$symbol${(tx.amountCents / 100).toStringAsFixed(2)}';
    final amount = isExpense ? '-$amountBody' : amountBody;

    final selection = enableSelection
        ? ref.watch(selectionControllerProvider)
        : const <String>{};
    final selecting = selection.isNotEmpty;
    final selected = selection.contains(tx.id);

    final catColor = cat == null ? c.textMuted : HexColor.fromHex(cat.color);
    final catIcon = cat == null ? LucideIcons.helpCircle : iconFor(cat.icon);
    final catLabel = cat == null
        ? '—'
        : (resolveDefaultName(AppL10n.of(context), cat.nameKey) ?? cat.name);
    final srcLabel = src == null
        ? null
        : (resolveDefaultName(AppL10n.of(context), src.nameKey) ?? src.name);

    return InkWell(
      onTap: () {
        if (enableSelection && selecting) {
          ref.read(selectionControllerProvider.notifier).toggle(tx.id);
        } else {
          context.push('/transactions/${tx.id}/edit');
        }
      },
      onLongPress: enableSelection
          ? () {
              HapticFeedback.mediumImpact();
              ref.read(selectionControllerProvider.notifier).toggle(tx.id);
            }
          : null,
      borderRadius: AppRadius.brXl,
      child: Container(
        color: selected ? c.mintSoft : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selecting)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: AppSpacing.x2),
                child: Icon(
                  selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 20,
                  color: selected ? c.action : c.textMuted,
                ),
              ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: catColor,
                shape: BoxShape.circle,
              ),
              child: Icon(catIcon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.x3),
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
                  if (txTags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final t in txTags)
                            TagPill(
                              label: resolveDefaultName(
                                      AppL10n.of(context), t.nameKey) ??
                                  t.name,
                              color: HexColor.fromHex(t.color),
                              compact: true,
                            ),
                        ],
                      ),
                    ),
                  if (tx.note != null && tx.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        tx.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.xs.copyWith(color: c.textBody),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: AppTypography.sm
                      .merge(AppTypography.mono)
                      .copyWith(
                        color: amountColor,
                        fontWeight: AppTypography.weightSemibold,
                      ),
                ),
                if (srcLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      srcLabel,
                      style: AppTypography.xs.copyWith(color: c.textMuted),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
