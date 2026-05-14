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
import 'stats_donut.dart';
import 'tag_pill.dart';
import 'type_pill_toggle.dart';

class CategoryDistributionCard extends ConsumerStatefulWidget {
  const CategoryDistributionCard({super.key});

  @override
  ConsumerState<CategoryDistributionCard> createState() => _CDState();
}

class _CDState extends ConsumerState<CategoryDistributionCard> {
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    final async = ref.watch(categoryDistributionProvider(_type));
    final cats = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    Category? findCat(String id) {
      for (final x in cats) {
        if (x.id == id) return x;
      }
      return null;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.donut_large, size: 18, color: c.textPrimary),
                const SizedBox(width: 6),
                Text(
                  l.statsDistCategoryTitle,
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
            const SizedBox(height: AppSpacing.x3),
            async.when(
              loading: () => _loading(context, l),
              error: (_, __) => _error(context, l),
              data: (data) {
                if (data.slices.isEmpty) {
                  return _empty(context, l.statsNoData);
                }
                final centerColor =
                    _type == TransactionType.expense ? c.expense : c.income;
                return Column(
                  children: [
                    StatsDonut(
                      slices: [
                        for (final s in data.slices)
                          DonutSlice(
                            color: _categoryColor(findCat(s.categoryId)),
                            value: s.totalCents.toDouble(),
                          ),
                      ],
                      centerLabel: _type == TransactionType.expense
                          ? l.statsDistCenterExpense
                          : l.statsDistCenterIncome,
                      centerAmount:
                          _formatAmount(data.totalCents, f.currency, _type),
                      centerColor: centerColor,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    _bounded(
                      children: [
                        for (final s in data.slices)
                          InkWell(
                            onTap: () => navigateToTransactions(
                              context,
                              ref,
                              categoryId: s.categoryId,
                            ),
                            child: _categoryRow(
                              context,
                              l,
                              findCat(s.categoryId),
                              s.totalCents,
                              f.currency,
                              _type,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TagDistributionCard extends ConsumerStatefulWidget {
  const TagDistributionCard({super.key, required this.cardKey});
  final GlobalKey cardKey;

  @override
  ConsumerState<TagDistributionCard> createState() => _TDState();
}

class _TDState extends ConsumerState<TagDistributionCard> {
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    final async = ref.watch(tagDistributionProvider(_type));
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const [];
    Tag? findTag(String id) {
      for (final x in tags) {
        if (x.id == id) return x;
      }
      return null;
    }

    return Card(
      key: widget.cardKey,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label_outline, size: 18, color: c.textPrimary),
                const SizedBox(width: 6),
                Text(
                  l.statsDistTagTitle,
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
            const SizedBox(height: AppSpacing.x3),
            async.when(
              loading: () => _loading(context, l),
              error: (_, __) => _error(context, l),
              data: (data) {
                if (data.slices.isEmpty && data.untaggedCents == 0) {
                  return _empty(context, l.statsNoTaggedData);
                }
                final centerColor =
                    _type == TransactionType.expense ? c.expense : c.income;
                return Column(
                  children: [
                    StatsDonut(
                      slices: [
                        for (final s in data.slices)
                          DonutSlice(
                            color: _tagColor(findTag(s.tagId)),
                            value: s.totalCents.toDouble(),
                          ),
                      ],
                      centerLabel: _type == TransactionType.expense
                          ? l.statsDistCenterExpense
                          : l.statsDistCenterIncome,
                      centerAmount:
                          _formatAmount(data.totalCents, f.currency, _type),
                      centerColor: centerColor,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    _bounded(
                      children: [
                        for (final s in data.slices)
                          InkWell(
                            onTap: () => navigateToTransactions(
                              context,
                              ref,
                              tagId: s.tagId,
                            ),
                            child: _tagRow(
                              context,
                              l,
                              findTag(s.tagId),
                              s.totalCents,
                              f.currency,
                              _type,
                            ),
                          ),
                        if (data.untaggedCents > 0)
                          InkWell(
                            onTap: () => navigateToTransactions(
                              context,
                              ref,
                              untagged: true,
                            ),
                            child: _untaggedRow(
                              context,
                              l,
                              data.untaggedCents,
                              f.currency,
                              _type,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _loading(BuildContext context, AppL10n l) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          l.statsLoading,
          style: AppTypography.sm.copyWith(color: context.appColors.textMuted),
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
          style: AppTypography.sm.copyWith(color: context.appColors.textMuted),
        ),
      ),
    );

Widget _bounded({required List<Widget> children}) {
  if (children.length <= 10) return Column(children: children);
  return ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 400),
    child: ListView(shrinkWrap: true, children: children),
  );
}

Widget _categoryRow(
  BuildContext context,
  AppL10n l,
  Category? cat,
  int cents,
  String currency,
  TransactionType type,
) {
  final c = context.appColors;
  final color = _categoryColor(cat);
  final iconKey = cat?.icon ?? 'tag';
  final name = cat == null
      ? '—'
      : (resolveDefaultName(l, cat.nameKey) ?? cat.name);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(iconFor(iconKey), size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
        Text(
          _formatAmount(cents, currency, type),
          style: AppTypography.sm.copyWith(
            fontFamily: 'monospace',
            color: type == TransactionType.expense ? c.expense : c.income,
          ),
        ),
      ],
    ),
  );
}

Widget _tagRow(
  BuildContext context,
  AppL10n l,
  Tag? tag,
  int cents,
  String currency,
  TransactionType type,
) {
  final c = context.appColors;
  final name = tag == null
      ? '—'
      : (resolveDefaultName(l, tag.nameKey) ?? tag.name);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        TagPill(label: name, color: _tagColor(tag), compact: true),
        const Spacer(),
        Text(
          _formatAmount(cents, currency, type),
          style: AppTypography.sm.copyWith(
            fontFamily: 'monospace',
            color: type == TransactionType.expense ? c.expense : c.income,
          ),
        ),
      ],
    ),
  );
}

Widget _untaggedRow(
  BuildContext context,
  AppL10n l,
  int cents,
  String currency,
  TransactionType type,
) {
  final c = context.appColors;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        TagPill(
          label: l.statsUntagged,
          color: c.textMuted,
          compact: true,
          italic: true,
        ),
        const Spacer(),
        Text(
          _formatAmount(cents, currency, type),
          style: AppTypography.sm.copyWith(
            fontFamily: 'monospace',
            color: type == TransactionType.expense ? c.expense : c.income,
          ),
        ),
      ],
    ),
  );
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
