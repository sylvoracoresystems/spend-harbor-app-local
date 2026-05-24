part of '../transaction_form.dart';

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({
    required this.type,
    required this.selected,
    required this.onPicked,
  });

  final TransactionType type;
  final String? selected;
  final ValueChanged<String?> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allCategoriesProvider);
    return async.when(
      data: (all) {
        final filtered = all.where((cat) => cat.type == type).toList();
        if (filtered.isEmpty) {
          return _OutlinedBox(
            child: Text(
              l.txEmptyCategory,
              style: AppTypography.sm.copyWith(color: c.textMuted),
            ),
          );
        }
        const spacing = AppSpacing.x2;
        const aspectRatio = 1.05;
        const maxVisibleRows = 3;
        const targetTileWidth = 90.0;

        return LayoutBuilder(
          builder: (ctx, cons) {
            // 列数随视口自适应（iPhone 4 列、iPad/横屏 6~8 列），
            // 保证单 tile 接近 90pt，避免宽屏下被强行拉成大色块。
            final crossCount = math.max(
              4,
              ((cons.maxWidth + spacing) / (targetTileWidth + spacing)).floor(),
            );
            final rows = (filtered.length / crossCount).ceil();
            final visibleRows = rows.clamp(1, maxVisibleRows);
            final tileWidth =
                (cons.maxWidth - spacing * (crossCount - 1)) / crossCount;
            final tileHeight = tileWidth / aspectRatio;
            final height =
                tileHeight * visibleRows + spacing * (visibleRows - 1);
            return SizedBox(
              height: height,
              child: GridView.builder(
                physics: rows > maxVisibleRows
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (ctx, i) {
                  final cat = filtered[i];
                  final isSel = selected == cat.id;
                  return _CategoryTile(
                    cat: cat,
                    selected: isSel,
                    onTap: () => onPicked(cat.id),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('$e'),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.cat,
    required this.selected,
    required this.onTap,
  });
  final Category cat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final iconColor = HexColor.fromHex(cat.color);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brXl,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1 + 2),
          decoration: BoxDecoration(
            color: selected ? c.mintSoft : c.surface,
            border: Border.all(
              color: selected ? c.action : c.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: AppRadius.brXl,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: c.action.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconFor(cat.icon), size: 14, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x1),
                child: Text(
                  _categoryDisplay(context, cat),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.xs.copyWith(
                    color: c.textBody,
                    fontWeight: AppTypography.weightMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _categoryDisplay(BuildContext context, Category c) {
  final localized = resolveDefaultName(AppL10n.of(context), c.nameKey);
  return localized ?? c.name;
}
