import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/utils/lookup_by_id.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../dashboard/presentation/dashboard_filter_bar.dart';
import '../application/transactions_list_controller.dart';
import 'transaction_list_row.dart';

part 'transactions_page/day_group.dart';
part 'transactions_page/list_summary.dart';

/// 交易列表页：过滤条 + 按日分组 + 多选批量操作。
class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(filteredTransactionsProvider);
    final selection = ref.watch(selectionControllerProvider);
    final selecting = selection.isNotEmpty;

    // Stats 跳转应用 category/tag/dateRange 临时筛选时弹 toast 提示。
    ref.listen<TransactionsFilter?>(transactionsFilterProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      if (prev == next) return;
      final msg = _filterLabel(context, ref, next);
      if (msg == null) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.funnel, size: 16, color: c.textMuted),
              const SizedBox(width: AppSpacing.x2),
              Flexible(
                child: Text(
                  msg,
                  style: AppTypography.sm.copyWith(color: c.textBody),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              InkWell(
                borderRadius: AppRadius.brLg,
                onTap: () {
                  ref.read(transactionsFilterProvider.notifier).state = null;
                  messenger.hideCurrentSnackBar();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x2,
                    vertical: AppSpacing.x1,
                  ),
                  child: Text(
                    l.txFilterClear,
                    style: AppTypography.sm.copyWith(
                      color: c.action,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 2500),
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXl,
            side: BorderSide(color: c.border),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x6,
            vertical: AppSpacing.x4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2,
          ),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
    });

    return RootPageScaffold(
      title: l.tabTransactions,
      customAppBar:
          selecting ? _buildSelectionAppBar(context, ref, selection) : null,
      actions: [
        IconButton(
          tooltip: l.recycleBinTitle,
          icon: const Icon(LucideIcons.trash2),
          onPressed: () => context.push('/transactions/recycle-bin'),
        ),
      ],
      pageHeader: const DashboardFilterBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return RootPageEmpty(text: l.txListEmpty);
          }
          final groups = groupByDay(rows);
          // 宽屏（iPad / 大屏横屏）下按 dashboard / settings 的卡片风格展示：
          // 左右留出 padding，每个 day group 包成带边框的圆角卡片。
          final isWide = MediaQuery.sizeOf(context).width >= 720;
          // Summary 固定在列表上方，滚动时不消失。
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ListSummary(rows: rows),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? AppSpacing.x4 : 0,
                    AppSpacing.x2,
                    isWide ? AppSpacing.x4 : 0,
                    AppSpacing.x2,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    return _DayGroupView(
                      group: groups[i],
                      cardStyle: isWide,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

PreferredSizeWidget _buildSelectionAppBar(
  BuildContext context,
  WidgetRef ref,
  Set<String> selection,
) {
  final l = AppL10n.of(context);
  return AppBar(
    leading: IconButton(
      tooltip: l.selectionCancel,
      icon: const Icon(LucideIcons.x),
      onPressed: () =>
          ref.read(selectionControllerProvider.notifier).clear(),
    ),
    title: Text(l.selectionTitle(selection.length)),
    actions: [
      IconButton(
        tooltip: l.selectionDelete,
        icon: const Icon(LucideIcons.trash2),
        onPressed: () => _confirmBulkDelete(context, ref, selection),
      ),
    ],
  );
}

/// 从 [filter] 派生 toast 文案。返回 null 表示无可展示的临时筛选。
String? _filterLabel(
  BuildContext context,
  WidgetRef ref,
  TransactionsFilter filter,
) {
  final l = AppL10n.of(context);
  if (filter.categoryId != null) {
    final categories = ref.read(allCategoriesProvider).valueOrNull ?? const [];
    final cat = categories.byId(filter.categoryId!);
    final name = cat == null
        ? filter.categoryId!
        : (resolveDefaultName(l, cat.nameKey) ?? cat.name);
    return l.txFilterAppliedCategory(name);
  }
  if (filter.tagId != null) {
    final tags = ref.read(allTagsProvider).valueOrNull ?? const [];
    final tag = tags.byId(filter.tagId!);
    final name = tag?.name ?? filter.tagId!;
    return l.txFilterAppliedTag(name);
  }
  if (filter.untagged) return l.txFilterAppliedUntagged;
  if (filter.hasDateRange) return l.txFilterAppliedDateRange;
  return null;
}

Future<void> _confirmBulkDelete(
  BuildContext context,
  WidgetRef ref,
  Set<String> selection,
) async {
  final l = AppL10n.of(context);
  final ok = await showConfirmDialog(
    context,
    title: l.selectionDeleteConfirmTitle(selection.length),
    body: l.selectionDeleteConfirmBody,
    confirmText: l.selectionDelete,
  );
  if (!ok) return;
  await ref
      .read(transactionDaoProvider)
      .bulkSoftDelete(selection.toList());
  ref.read(selectionControllerProvider.notifier).clear();
}
