import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/category_form_controller.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsCategories),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: l.txTypeExpense),
            Tab(text: l.txTypeIncome),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _CategoryList(type: TransactionType.expense),
          _CategoryList(type: TransactionType.income),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/settings/categories/new',
          extra: _tab.index == 0
              ? TransactionType.expense
              : TransactionType.income,
        ),
        icon: const Icon(LucideIcons.plus),
        label: Text(l.catAdd),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.type});
  final TransactionType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(categoriesByTypeProvider(type));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Text(
              type == TransactionType.expense
                  ? l.catEmptyExpense
                  : l.catEmptyIncome,
              style: AppTypography.sm.copyWith(color: c.textMuted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
          itemCount: rows.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: c.border, indent: AppSpacing.x4),
          itemBuilder: (context, i) => _CategoryRow(cat: rows[i]),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.cat});
  final Category cat;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final label =
        resolveDefaultName(AppL10n.of(context), cat.nameKey) ?? cat.name;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _hexToColor(cat.color).withValues(alpha: 0.15),
          borderRadius: AppRadius.brFull,
        ),
        child: Icon(iconFor(cat.icon), color: _hexToColor(cat.color), size: 18),
      ),
      title: Text(label,
          style: AppTypography.sm.copyWith(
            color: c.actionInk,
            fontWeight: AppTypography.weightSemibold,
          )),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
      onTap: () =>
          context.push('/settings/categories/${cat.id}/edit'),
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
