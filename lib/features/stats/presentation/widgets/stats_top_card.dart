import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../data/database/app_database_provider.dart';
import '../../../../data/seed/default_name_resolver.dart';
import '../../../../domain/enums/transaction_type.dart';
import '../../../../domain/value_objects/currency.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/icons/icon_registry.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../application/stats_controller.dart';
import '../../application/stats_filter_provider.dart';
import '../stats_navigation.dart';
import '../../../../shared/widgets/tag_pill.dart';
import 'type_pill_toggle.dart';

enum TopMode { category, tag }

class StatsTopCard extends ConsumerStatefulWidget {
  const StatsTopCard({super.key, required this.onJumpToTagDist});
  final VoidCallback onJumpToTagDist;

  @override
  ConsumerState<StatsTopCard> createState() => _Top();
}

class _Top extends ConsumerState<StatsTopCard> {
  TopMode _mode = TopMode.category;
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, size: 18, color: c.warning),
                const SizedBox(width: 6),
                Text(
                  l.statsTopTitle,
                  style: AppTypography.base.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                TypePillToggle(
                  value: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            Row(
              children: [
                _TabBtn(
                  label: l.statsTopByCategory,
                  active: _mode == TopMode.category,
                  onTap: () => setState(() => _mode = TopMode.category),
                ),
                const SizedBox(width: 16),
                _TabBtn(
                  label: l.statsTopByTag,
                  active: _mode == TopMode.tag,
                  onTap: () => setState(() => _mode = TopMode.tag),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            if (_mode == TopMode.category)
              _ByCategoryBody(type: _type, currency: f.currency)
            else
              _ByTagBody(
                type: _type,
                currency: f.currency,
                onJumpToTagDist: widget.onJumpToTagDist,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? c.action : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.sm.copyWith(
            color: active ? c.action : c.textMuted,
            fontWeight: active
                ? AppTypography.weightSemibold
                : AppTypography.weightNormal,
          ),
        ),
      ),
    );
  }
}

class _ByCategoryBody extends ConsumerWidget {
  const _ByCategoryBody({required this.type, required this.currency});
  final TransactionType type;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(topByCategoryProvider(type));
    final cats = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const [];
    Category? findCat(String id) {
      for (final x in cats) {
        if (x.id == id) return x;
      }
      return null;
    }

    Tag? findTag(String id) {
      for (final x in tags) {
        if (x.id == id) return x;
      }
      return null;
    }

    return async.when(
      loading: () => _loading(context, l),
      error: (_, __) => _error(context, l),
      data: (rows) {
        if (rows.isEmpty) return _empty(context, l.statsNoData);
        return Column(
          children: [
            for (final row in rows)
              InkWell(
                onTap: () => navigateToTransactions(
                  context,
                  ref,
                  categoryId: row.categoryId,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _categoryAvatar(findCat(row.categoryId)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _categoryName(l, findCat(row.categoryId)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatAmount(row.totalCents, currency, type),
                            style: AppTypography.base.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: AppTypography.weightSemibold,
                              color: type == TransactionType.expense
                                  ? c.expense
                                  : c.income,
                            ),
                          ),
                        ],
                      ),
                      if (row.tagFrequencies.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 36, top: 4),
                          child: _tagPills(l, row.tagFrequencies, findTag),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 36, top: 4),
                        child: Text(
                          l.statsTopCountLabel(row.count),
                          style:
                              AppTypography.xs.copyWith(color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tagPills(
    AppL10n l,
    Map<String, int> freq,
    Tag? Function(String) findTag,
  ) {
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final extra = sorted.length - top.length;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final e in top)
          TagPill(
            label: _tagName(l, findTag(e.key)),
            color: _tagColor(findTag(e.key)),
            compact: true,
          ),
        if (extra > 0)
          TagPill(
            label: '+$extra',
            color: const Color(0xFFBBBBBB),
            compact: true,
          ),
      ],
    );
  }
}

class _ByTagBody extends ConsumerWidget {
  const _ByTagBody({
    required this.type,
    required this.currency,
    required this.onJumpToTagDist,
  });
  final TransactionType type;
  final String currency;
  final VoidCallback onJumpToTagDist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(topByTagProvider(type));
    final cats = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const [];
    Category? findCat(String id) {
      for (final x in cats) {
        if (x.id == id) return x;
      }
      return null;
    }

    Tag? findTag(String id) {
      for (final x in tags) {
        if (x.id == id) return x;
      }
      return null;
    }

    return async.when(
      loading: () => _loading(context, l),
      error: (_, __) => _error(context, l),
      data: (agg) {
        if (agg.rows.isEmpty && agg.untagged == null) {
          return _empty(context, l.statsNoTaggedData);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in agg.rows)
              InkWell(
                onTap: () =>
                    navigateToTransactions(context, ref, tagId: row.tagId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TagPill(
                            label: _tagName(l, findTag(row.tagId)),
                            color: _tagColor(findTag(row.tagId)),
                          ),
                          const Spacer(),
                          Text(
                            _formatAmount(row.totalCents, currency, type),
                            style: AppTypography.base.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: AppTypography.weightSemibold,
                              color: type == TransactionType.expense
                                  ? c.expense
                                  : c.income,
                            ),
                          ),
                        ],
                      ),
                      if (row.topCategories.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 6),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final tc in row.topCategories)
                                _categoryChip(
                                  context,
                                  _categoryName(l, findCat(tc.categoryId)),
                                  _categoryColor(findCat(tc.categoryId)),
                                  _formatAmount(tc.totalCents, currency, type),
                                ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          l.statsTopCountLabel(row.count),
                          style:
                              AppTypography.xs.copyWith(color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (agg.untagged != null)
              InkWell(
                onTap: () =>
                    navigateToTransactions(context, ref, untagged: true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      TagPill(
                        label: l.statsUntagged,
                        color: c.textMuted,
                        italic: true,
                      ),
                      const Spacer(),
                      Text(
                        _formatAmount(
                            agg.untagged!.totalCents, currency, type),
                        style: AppTypography.base.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: AppTypography.weightSemibold,
                          color: type == TransactionType.expense
                              ? c.expense
                              : c.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            InkWell(
              onTap: onJumpToTagDist,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l.statsTopMultiTagNote,
                  style: AppTypography.xs.copyWith(
                    fontStyle: FontStyle.italic,
                    color: c.textMuted,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _categoryAvatar(Category? cat) {
  final color = _categoryColor(cat);
  final iconKey = cat?.icon ?? 'tag';
  return Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Icon(iconFor(iconKey), size: 16, color: Colors.white),
  );
}

Widget _categoryChip(
  BuildContext context,
  String name,
  Color color,
  String amount,
) {
  final c = context.appColors;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: AppTypography.xs),
        Text(
          amount,
          style: AppTypography.xs.copyWith(
            fontFamily: 'monospace',
            color: c.textMuted,
          ),
        ),
      ],
    ),
  );
}

Widget _loading(BuildContext context, AppL10n l) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          l.statsLoading,
          style:
              AppTypography.sm.copyWith(color: context.appColors.textMuted),
        ),
      ),
    );

Widget _error(BuildContext context, AppL10n l) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          l.statsError,
          style: AppTypography.sm.copyWith(color: context.appColors.expense),
        ),
      ),
    );

Widget _empty(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style:
              AppTypography.sm.copyWith(color: context.appColors.textMuted),
        ),
      ),
    );

String _categoryName(AppL10n l, Category? cat) {
  if (cat == null) return '—';
  return resolveDefaultName(l, cat.nameKey) ?? cat.name;
}

String _tagName(AppL10n l, Tag? tag) {
  if (tag == null) return '—';
  return resolveDefaultName(l, tag.nameKey) ?? tag.name;
}

Color _categoryColor(Category? c) =>
    c == null ? const Color(0xFF999999) : _hexToColor(c.color);
Color _tagColor(Tag? t) =>
    t == null ? const Color(0xFF999999) : _hexToColor(t.color);

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}

String _formatAmount(int cents, String currency, TransactionType type) {
  final abs = (cents.abs() / 100).toStringAsFixed(2);
  final sym = Currency.byCode(currency).symbol;
  return type == TransactionType.expense ? '-$sym$abs' : '$sym$abs';
}
