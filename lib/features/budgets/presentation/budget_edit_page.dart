import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/budget_period.dart';
import '../../../domain/enums/budget_scope.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/budget_form_controller.dart';
import '../application/budget_period_alignment.dart';

class BudgetEditPage extends ConsumerStatefulWidget {
  const BudgetEditPage({super.key, this.id});
  final String? id;

  @override
  ConsumerState<BudgetEditPage> createState() => _BudgetEditPageState();
}

class _BudgetEditPageState extends ConsumerState<BudgetEditPage> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    ref.listenManual<BudgetFormState>(_provider(), (prev, next) {
      if (prev?.amountInput != next.amountInput &&
          _amountCtrl.text != next.amountInput) {
        _amountCtrl.text = next.amountInput;
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  AutoDisposeStateNotifierProvider<BudgetFormController, BudgetFormState>
      _provider() =>
          budgetFormControllerProvider(widget.id);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final state = ref.watch(_provider());
    final notifier = ref.read(_provider().notifier);

    final effectiveStart = state.startsOn ??
        alignToPeriodStart(DateTime.now(), state.period);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditing ? l.budgetEditTitle : l.budgetNewTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: [
          _SectionLabel(text: l.budgetFieldPeriod),
          const SizedBox(height: AppSpacing.x2),
          SegmentedButton<BudgetPeriod>(
            segments: [
              ButtonSegment(
                value: BudgetPeriod.week,
                label: Text(l.budgetPeriodWeek),
              ),
              ButtonSegment(
                value: BudgetPeriod.month,
                label: Text(l.budgetPeriodMonth),
              ),
              ButtonSegment(
                value: BudgetPeriod.year,
                label: Text(l.budgetPeriodYear),
              ),
            ],
            selected: {state.period},
            onSelectionChanged: (s) => notifier.setPeriod(s.first),
          ),
          const SizedBox(height: AppSpacing.x4),
          _SectionLabel(text: l.budgetFieldScope),
          const SizedBox(height: AppSpacing.x2),
          SegmentedButton<BudgetScope>(
            segments: [
              ButtonSegment(
                value: BudgetScope.total,
                label: Text(l.budgetScopeTotal),
              ),
              ButtonSegment(
                value: BudgetScope.category,
                label: Text(l.budgetScopeCategory),
              ),
            ],
            selected: {state.scope},
            onSelectionChanged: (s) => notifier.setScope(s.first),
          ),
          if (state.scope == BudgetScope.category) ...[
            const SizedBox(height: AppSpacing.x4),
            _CategoryDropdown(
              value: state.categoryId,
              onPicked: notifier.setCategory,
            ),
          ],
          const SizedBox(height: AppSpacing.x4),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: l.budgetFieldAmount,
              prefixText:
                  '${Currency.byCode(state.currency).symbol}  ',
            ),
            onChanged: notifier.setAmount,
          ),
          const SizedBox(height: AppSpacing.x4),
          DropdownButtonFormField<String>(
            value: state.currency,
            decoration: InputDecoration(labelText: l.budgetFieldCurrency),
            items: [
              for (final ccy in Currency.all)
                DropdownMenuItem(
                  value: ccy.code,
                  child: Text('${ccy.code} · ${ccy.symbol}'),
                ),
            ],
            onChanged: (v) {
              if (v != null) notifier.setCurrency(v);
            },
          ),
          const SizedBox(height: AppSpacing.x4),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: effectiveStart,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (picked != null) notifier.setStartsOn(picked);
            },
            child: InputDecorator(
              decoration:
                  InputDecoration(labelText: l.budgetFieldStartsOn),
              child: Text(
                formatIsoDate(
                    alignToPeriodStart(effectiveStart, state.period)),
                style: AppTypography.sm,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          FilledButton(
            onPressed: state.submitting
                ? null
                : () async {
                    final err = await notifier.submit();
                    if (!context.mounted) return;
                    if (err == null) {
                      Navigator.of(context).pop(true);
                      return;
                    }
                    final msg = switch (err) {
                      BudgetFormError.amountInvalid => l.budgetErrAmount,
                      BudgetFormError.categoryRequired =>
                        l.budgetErrCategoryRequired,
                    };
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  },
            child: Text(l.txSave),
          ),
          if (state.isEditing) ...[
            const SizedBox(height: AppSpacing.x3),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: c.expense),
              onPressed: state.submitting
                  ? null
                  : () => _confirmDelete(context, notifier),
              child: Text(l.txDelete),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BudgetFormController notifier,
  ) async {
    final l = AppL10n.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.budgetDeleteConfirmTitle),
        content: Text(l.budgetDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.txCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.txDelete),
          ),
        ],
      ),
    );
    if (yes == true) {
      await notifier.delete();
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Text(
      text,
      style: AppTypography.xs.copyWith(
        color: c.textMuted,
        fontWeight: AppTypography.weightMedium,
      ),
    );
  }
}

class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown({required this.value, required this.onPicked});
  final String? value;
  final ValueChanged<String?> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final async = ref.watch(allCategoriesProvider);
    return async.when(
      data: (all) {
        // 预算分类只针对支出（spec §4.4）
        final cats = all.where((c) => c.type == TransactionType.expense).toList();
        final valid =
            value != null && cats.any((c) => c.id == value);
        return DropdownButtonFormField<String>(
          value: valid ? value : null,
          decoration: InputDecoration(labelText: l.budgetFieldCategory),
          items: [
            for (final c in cats)
              DropdownMenuItem(
                value: c.id,
                child: Text(
                  resolveDefaultName(AppL10n.of(context), c.nameKey) ?? c.name,
                ),
              ),
          ],
          onChanged: onPicked,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
    );
  }
}
