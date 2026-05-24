import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../shared/utils/hex_color.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// 超过该阈值时显示搜索框。
const int _kSearchThreshold = 15;

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allCategoriesProvider);

    return SubPageScaffold(
      title: l.settingsCategories,
      actions: [
        IconButton(
          tooltip: l.catAdd,
          icon: const Icon(LucideIcons.plus),
          onPressed: () => context.push('/settings/categories/new'),
        ),
      ],
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                l.catEmpty,
                style: AppTypography.sm.copyWith(color: c.textMuted),
              ),
            );
          }
          final filtered = _filter(context, rows, _query);
          return Column(
            children: [
              if (rows.length > _kSearchThreshold)
                _SearchField(
                  hint: l.catSearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.x2),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: c.border,
                      indent: AppSpacing.x4),
                  itemBuilder: (context, i) =>
                      _CategoryRow(cat: filtered[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Category> _filter(
      BuildContext context, List<Category> rows, String q) {
    final l = AppL10n.of(context);
    if (q.trim().isEmpty) return rows;
    final needle = q.trim().toLowerCase();
    return rows.where((r) {
      final name = (resolveDefaultName(l, r.nameKey) ?? r.name).toLowerCase();
      return name.contains(needle);
    }).toList();
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x2,
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTypography.sm.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(LucideIcons.search, size: 18, color: c.textMuted),
          hintText: hint,
          hintStyle: AppTypography.sm.copyWith(color: c.textMuted),
          filled: true,
          fillColor: c.surface,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x3, vertical: AppSpacing.x3),
          border: OutlineInputBorder(
            borderRadius: AppRadius.brXl,
            borderSide: BorderSide(color: c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.brXl,
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.brXl,
            borderSide: BorderSide(color: c.action),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.cat});
  final Category cat;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final label = resolveDefaultName(l, cat.nameKey) ?? cat.name;
    final color = HexColor.fromHex(cat.color);
    final isIncome = cat.type == TransactionType.income;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.brFull,
        ),
        child: Icon(iconFor(cat.icon), color: Colors.white, size: 18),
      ),
      title: Text(label,
          style: AppTypography.sm.copyWith(
            color: c.actionInk,
            fontWeight: AppTypography.weightSemibold,
          )),
      subtitle: Text(
        isIncome ? l.catTypeIncomeBadge : l.catTypeExpenseBadge,
        style: AppTypography.xs.copyWith(
          color: isIncome ? c.income : c.expense,
          fontWeight: AppTypography.weightSemibold,
          letterSpacing: 0.5,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
      onTap: () => context.push('/settings/categories/${cat.id}/edit'),
    );
  }
}
