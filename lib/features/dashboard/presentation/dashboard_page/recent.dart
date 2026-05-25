part of '../dashboard_page.dart';

/// Dashboard 最近交易卡片：列出近 N 条交易，空列表则不渲染。
class _RecentSection extends ConsumerWidget {
  const _RecentSection({required this.asyncRows});
  final AsyncValue<List<Transaction>> asyncRows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final rows = asyncRows.valueOrNull ?? const <Transaction>[];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.dashRecent,
                style: AppTypography.xs.copyWith(
                  color: c.textMuted,
                  fontWeight: AppTypography.weightMedium,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/transactions'),
                child: Text(
                  l.dashViewAll,
                  style: AppTypography.xs.copyWith(
                    color: c.action,
                    fontWeight: AppTypography.weightSemibold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.brXl,
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                TransactionListRow(tx: rows[i]),
                if (i < rows.length - 1) Divider(height: 1, color: c.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
