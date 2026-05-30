part of '../transaction_form.dart';

/// 标签区：搜索 + 排序（选中→近 30d 频次→新→旧）+ 展开/收起。
class _TagsSection extends ConsumerWidget {
  const _TagsSection({
    required this.selectedIds,
    required this.query,
    required this.expanded,
    required this.searchCtrl,
    required this.onQueryChanged,
    required this.onToggleExpand,
    required this.onToggleTag,
    required this.onCreateTag,
  });

  final Set<String> selectedIds;
  final String query;
  final bool expanded;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onToggleTag;
  final ValueChanged<String> onCreateTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final tagsAsync = ref.watch(allTagsProvider);
    final usageAsync = ref.watch(tagUsageLast30dProvider);
    final usage = usageAsync.valueOrNull ?? const <String, int>{};

    return tagsAsync.when(
      data: (all) {
        // 排序：选中置顶 → 近 30 天频次降序 → 创建时间倒序
        final sorted = [...all]..sort((a, b) {
          final aSel = selectedIds.contains(a.id) ? 1 : 0;
          final bSel = selectedIds.contains(b.id) ? 1 : 0;
          if (aSel != bSel) return bSel - aSel;
          final aU = usage[a.id] ?? 0;
          final bU = usage[b.id] ?? 0;
          if (aU != bU) return bU - aU;
          return b.createdAt.compareTo(a.createdAt);
        });

        final q = query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? sorted
            : sorted.where((t) {
                final display = _tagDisplay(context, t).toLowerCase();
                return display.contains(q) ||
                    t.name.toLowerCase().contains(q);
              }).toList();

        final collapsedLimit = 16;
        final showAll = expanded || q.isNotEmpty;
        final visible =
            showAll ? filtered : filtered.take(collapsedLimit).toList();
        final overflow = filtered.length - visible.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OutlinedBox(
              height: _kFieldHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
              child: TextField(
                controller: searchCtrl,
                style: AppTypography.sm.copyWith(color: c.textPrimary),
                decoration: _flatDecoration(
                  hint: l.txTagSearchPlaceholder,
                  hintStyle: AppTypography.sm.copyWith(color: c.textHint),
                ),
                onChanged: onQueryChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            if (filtered.isEmpty)
              // 搜索无匹配：直接给「创建并选中」入口（query 非空时才提供）。
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
                child: q.isEmpty
                    ? Text(
                        l.txTagNoMatch,
                        style: AppTypography.sm.copyWith(color: c.textMuted),
                      )
                    : _CreateTagChip(
                        label: l.txTagCreateAction(query.trim()),
                        onTap: () => onCreateTag(query.trim()),
                      ),
              )
            else
              Wrap(
                spacing: AppSpacing.x1 + 2,
                runSpacing: AppSpacing.x1 + 2,
                children: [
                  for (final t in visible)
                    _TagChip(
                      label: _tagDisplay(context, t),
                      selected: selectedIds.contains(t.id),
                      onTap: () => onToggleTag(t.id),
                    ),
                  if (!showAll && overflow > 0)
                    _MoreChip(
                      label: l.txTagMore(overflow),
                      onTap: onToggleExpand,
                    ),
                  if (expanded && q.isEmpty)
                    _MoreChip(label: l.txTagLess, onTap: onToggleExpand),
                ],
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('$e'),
    );
  }
}

/// 标签 chip：选中态给品牌色填充 + 微阴影。
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brFull,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2 + 2,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: selected ? c.action : c.surface,
            border: Border.all(color: selected ? c.action : c.border),
            borderRadius: AppRadius.brFull,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: c.action.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTypography.xs.copyWith(
              color: selected ? Colors.white : c.textBody,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
        ),
      ),
    );
  }
}

///「+N 更多 / 收起」展开切换 chip。
class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      borderRadius: AppRadius.brFull,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brFull,
          border: Border.all(color: c.border, style: BorderStyle.solid),
        ),
        child: Text(
          label,
          style: AppTypography.xs.copyWith(color: c.textMuted),
        ),
      ),
    );
  }
}

String _tagDisplay(BuildContext context, Tag t) {
  final localized = resolveDefaultName(AppL10n.of(context), t.nameKey);
  return localized ?? t.name;
}

/// 搜索无匹配时的「创建并选中」chip：用 + 图标 + 品牌色描边与普通 tag chip 区分。
class _CreateTagChip extends StatelessWidget {
  const _CreateTagChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brFull,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2 + 2,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.action, width: 1),
            borderRadius: AppRadius.brFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.plus, size: 14, color: c.action),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.xs.copyWith(
                  color: c.action,
                  fontWeight: AppTypography.weightMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
