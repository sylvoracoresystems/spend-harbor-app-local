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
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/pill_segmented.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../shared/widgets/section_label.dart';
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

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SubPageScaffold(
      title: state.isEditing ? l.budgetEditTitle : l.budgetNewTitle,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x6 + bottomInset,
        ),
        children: [
          SectionLabel(l.budgetFieldPeriod),
          const SizedBox(height: AppSpacing.x2),
          PillSegmented<BudgetPeriod>(
            value: state.period,
            segments: [
              PillSegment(
                value: BudgetPeriod.week,
                label: l.budgetPeriodWeek,
              ),
              PillSegment(
                value: BudgetPeriod.month,
                label: l.budgetPeriodMonth,
              ),
              PillSegment(
                value: BudgetPeriod.year,
                label: l.budgetPeriodYear,
              ),
            ],
            onChanged: notifier.setPeriod,
          ),
          const SizedBox(height: AppSpacing.x4),
          SectionLabel(l.budgetFieldScope),
          const SizedBox(height: AppSpacing.x2),
          PillToggle<BudgetScope>(
            value: state.scope,
            first: PillToggleOption(
              value: BudgetScope.total,
              label: l.budgetScopeTotal,
              activeColor: c.action,
            ),
            second: PillToggleOption(
              value: BudgetScope.category,
              label: l.budgetScopeCategory,
              activeColor: c.action,
            ),
            onChanged: notifier.setScope,
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
    final ok = await showConfirmDialog(
      context,
      title: l.budgetDeleteConfirmTitle,
      body: l.budgetDeleteConfirmBody,
    );
    if (!ok) return;
    await notifier.delete();
    if (context.mounted) Navigator.of(context).pop(true);
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
