import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../data/database/app_database_provider.dart';
import '../../../../data/seed/default_name_resolver.dart';
import '../../../../domain/enums/transaction_type.dart';
import '../../../../domain/value_objects/currency.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/icons/icon_registry.dart';
import '../../../../shared/utils/hex_color.dart';
import '../../../../shared/utils/lookup_by_id.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../application/stats_controller.dart';
import '../../application/stats_filter_provider.dart';
import '../stats_navigation.dart';
import 'stats_donut.dart';
import 'stats_section_card.dart';
import '../../../../shared/widgets/tag_pill.dart';
import 'type_pill_toggle.dart';

/// 分类分布卡：环形图 + 列表，可切换收/支类型。
class CategoryDistributionCard extends ConsumerStatefulWidget {
  const CategoryDistributionCard({super.key});

  @override
  ConsumerState<CategoryDistributionCard> createState() => _CDState();
}

/// 持有当前选中的收/支类型。
class _CDState extends ConsumerState<CategoryDistributionCard> {
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    final async = ref.watch(categoryDistributionProvider(_type));
    final cats = ref.watch(allCategoriesProvider).valueOrNull ?? const [];

    return StatsSectionCard(
      icon: Icons.pie_chart,
      iconColor: c.info,
      title: l.statsDistCategoryTitle,
      trailing: TypePillToggle(
        value: _type,
        onChanged: (v) => setState(() => _type = v),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.x3),
          async.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading: () => StatsCardPlaceholder.loading(context, l),
            error: (_, __) => StatsCardPlaceholder.error(context, l),
            data: (data) {
              if (data.slices.isEmpty) {
                return StatsCardPlaceholder.empty(context, l.statsNoData);
              }
              final centerColor =
                  _type == TransactionType.expense ? c.expense : c.income;
              return Column(
                children: [
                  StatsDonut(
                    slices: [
                      for (final s in data.slices)
                        DonutSlice(
                          color: _categoryColor(cats.byId(s.categoryId)),
                          value: s.totalCents.toDouble(),
                          icon: iconFor(cats.byId(s.categoryId)?.icon ?? 'tag'),
                        ),
                    ],
                    centerLabel:
                        _type == TransactionType.expense
                            ? l.statsDistCenterExpense
                            : l.statsDistCenterIncome,
                    centerAmount: _formatAmount(
                      data.totalCents,
                      f.currency,
                      _type,
                    ),
                    centerColor: centerColor,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _bounded(
                    children: [
                      for (final s in data.slices)
                        InkWell(
                          onTap:
                              () => navigateToTransactions(
                                context,
                                ref,
                                categoryId: s.categoryId,
                              ),
                          child: _categoryRow(
                            context,
                            l,
                            cats.byId(s.categoryId),
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
    );
  }
}

/// 标签分布卡：环形图 + 列表，可切换收/支类型；接受外部 GlobalKey 供跨卡跳转。
class TagDistributionCard extends ConsumerStatefulWidget {
  const TagDistributionCard({super.key, required this.cardKey});
  final GlobalKey cardKey;

  @override
  ConsumerState<TagDistributionCard> createState() => _TDState();
}

/// 持有当前选中的收/支类型。
class _TDState extends ConsumerState<TagDistributionCard> {
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    final async = ref.watch(tagDistributionProvider(_type));
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const [];

    return StatsSectionCard(
      cardKey: widget.cardKey,
      icon: Icons.local_offer,
      iconColor: c.expense,
      title: l.statsDistTagTitle,
      trailing: TypePillToggle(
        value: _type,
        onChanged: (v) => setState(() => _type = v),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.x3),
          async.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading: () => StatsCardPlaceholder.loading(context, l),
            error: (_, __) => StatsCardPlaceholder.error(context, l),
            data: (data) {
              if (data.slices.isEmpty && data.untaggedCents == 0) {
                return StatsCardPlaceholder.empty(context, l.statsNoTaggedData);
              }
              final centerColor =
                  _type == TransactionType.expense ? c.expense : c.income;
              return Column(
                children: [
                  StatsDonut(
                    slices: [
                      for (final s in data.slices)
                        DonutSlice(
                          color: _tagColor(tags.byId(s.tagId)),
                          value: s.totalCents.toDouble(),
                        ),
                    ],
                    centerLabel:
                        _type == TransactionType.expense
                            ? l.statsDistCenterExpense
                            : l.statsDistCenterIncome,
                    centerAmount: _formatAmount(
                      data.totalCents,
                      f.currency,
                      _type,
                    ),
                    centerColor: centerColor,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _bounded(
                    children: [
                      for (final s in data.slices)
                        InkWell(
                          onTap:
                              () => navigateToTransactions(
                                context,
                                ref,
                                tagId: s.tagId,
                              ),
                          child: _tagRow(
                            context,
                            l,
                            tags.byId(s.tagId),
                            s.totalCents,
                            f.currency,
                            _type,
                          ),
                        ),
                      if (data.untaggedCents > 0)
                        InkWell(
                          onTap:
                              () => navigateToTransactions(
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
    );
  }
}

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
  final name =
      cat == null ? '—' : (resolveDefaultName(l, cat.nameKey) ?? cat.name);
  return Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: c.borderSoft)),
    ),
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(iconFor(iconKey), size: 16, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.x2),
        Expanded(
          child: Text(
            name,
            style: AppTypography.sm.copyWith(color: c.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          _formatAmount(cents, currency, type),
          style: AppTypography.base.copyWith(
            fontFamily: 'monospace',
            fontWeight: AppTypography.weightSemibold,
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
  final name =
      tag == null ? '—' : (resolveDefaultName(l, tag.nameKey) ?? tag.name);
  return Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: c.borderSoft)),
    ),
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
    child: Row(
      children: [
        Flexible(
          child: TagPill(label: name, color: _tagColor(tag), compact: true),
        ),
        const SizedBox(width: AppSpacing.x2),
        const Spacer(),
        Text(
          _formatAmount(cents, currency, type),
          style: AppTypography.base.copyWith(
            fontFamily: 'monospace',
            fontWeight: AppTypography.weightSemibold,
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
  return Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: c.borderSoft)),
    ),
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
    child: Row(
      children: [
        Flexible(
          child: TagPill(
            label: l.statsUntagged,
            color: c.textMuted,
            italic: true,
            compact: true,
          ),
        ),
        const SizedBox(width: AppSpacing.x2),
        const Spacer(),
        Text(
          _formatAmount(cents, currency, type),
          style: AppTypography.base.copyWith(
            fontFamily: 'monospace',
            fontWeight: AppTypography.weightSemibold,
            color: type == TransactionType.expense ? c.expense : c.income,
          ),
        ),
      ],
    ),
  );
}

Color _categoryColor(Category? c) =>
    c == null ? AppColors.light.textHint : HexColor.fromHex(c.color);
Color _tagColor(Tag? t) =>
    t == null ? AppColors.light.textHint : HexColor.fromHex(t.color);

String _formatAmount(int cents, String currency, TransactionType type) {
  final abs = (cents.abs() / 100).toStringAsFixed(2);
  final sym = Currency.byCode(currency).symbol;
  return type == TransactionType.expense ? '-$sym$abs' : '$sym$abs';
}
