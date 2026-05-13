import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/transaction_form_controller.dart';

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({super.key, this.editId});

  /// 为 null 时是新建。
  final String? editId;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
    // 编辑模式：异步加载完成后同步 controller 文本。
    final notifier = ref.read(_provider().notifier);
    final initial = ref.read(_provider());
    _amountCtrl.text = initial.amountInput;
    _noteCtrl.text = initial.note;
    if (widget.editId != null) {
      // 监听一次以同步加载后的状态到 TextEditingController。
      ref.listenManual<TransactionFormState>(_provider(), (prev, next) {
        if (prev?.amountInput != next.amountInput) {
          _amountCtrl.text = next.amountInput;
        }
        if (prev?.note != next.note) _noteCtrl.text = next.note;
      });
    }
    // 防止 lint 警告 unused
    notifier;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  AutoDisposeStateNotifierProvider<TransactionFormController,
          TransactionFormState>
      _provider() =>
          transactionFormControllerProvider(widget.editId);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final state = ref.watch(_provider());
    final notifier = ref.read(_provider().notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x4),
      children: [
        _TypeSelector(
          value: state.type,
          onChanged: (t) {
            notifier.setType(t);
            // type 变了之后旧 category 可能不再匹配
            notifier.setCategory(null);
          },
        ),
        const SizedBox(height: AppSpacing.x4),
        _AmountField(
          controller: _amountCtrl,
          label: l.txFieldAmount,
          onChanged: notifier.setAmount,
          currencyHint: _currencySymbolFor(state.sourceId, ref),
        ),
        const SizedBox(height: AppSpacing.x4),
        _SourceField(
          state: state,
          onPicked: notifier.setSource,
        ),
        const SizedBox(height: AppSpacing.x4),
        _CategoryField(
          state: state,
          onPicked: notifier.setCategory,
        ),
        const SizedBox(height: AppSpacing.x4),
        _DateField(
          value: state.date ?? DateTime.now(),
          onPicked: notifier.setDate,
        ),
        const SizedBox(height: AppSpacing.x4),
        _TagsField(state: state, onToggle: notifier.toggleTag),
        const SizedBox(height: AppSpacing.x4),
        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: l.txFieldNote,
            hintText: l.txNotePlaceholder,
          ),
          onChanged: notifier.setNote,
        ),
        const SizedBox(height: AppSpacing.x6),
        FilledButton(
          onPressed: state.submitting
              ? null
              : () async {
                  final error = notifier.validate();
                  if (error != null) {
                    _showError(context, _messageFor(l, error));
                    return;
                  }
                  final ok = await notifier.submit();
                  if (ok && context.mounted) Navigator.of(context).pop(true);
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
    );
  }

  String _messageFor(AppL10n l, TransactionFormError e) {
    return switch (e) {
      TransactionFormError.amountRequired => l.txErrAmountRequired,
      TransactionFormError.amountInvalid => l.txErrAmountInvalid,
      TransactionFormError.categoryRequired => l.txErrCategoryRequired,
      TransactionFormError.sourceRequired => l.txErrSourceRequired,
    };
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionFormController notifier,
  ) async {
    final l = AppL10n.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.txDeleteConfirmTitle),
        content: Text(l.txDeleteConfirmBody),
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

String? _currencySymbolFor(String? sourceId, WidgetRef ref) {
  if (sourceId == null) return null;
  final sources = ref.read(allSourcesProvider).valueOrNull;
  if (sources == null) return null;
  final src = sources.where((s) => s.id == sourceId).firstOrNull;
  if (src == null) return null;
  return Currency.byCode(src.currency).symbol;
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});
  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return SegmentedButton<TransactionType>(
      segments: [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text(l.txTypeExpense),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text(l.txTypeIncome),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.currencyHint,
  });
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final String? currencyHint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: AppTypography.lg.copyWith(
        fontWeight: AppTypography.weightSemibold,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: currencyHint == null ? null : '$currencyHint  ',
      ),
      onChanged: onChanged,
    );
  }
}

class _SourceField extends ConsumerWidget {
  const _SourceField({required this.state, required this.onPicked});
  final TransactionFormState state;
  final ValueChanged<String?> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final async = ref.watch(allSourcesProvider);
    return async.when(
      data: (sources) {
        if (sources.isEmpty) {
          return _ReadOnlyTile(label: l.txFieldSource, value: l.txEmptySource);
        }
        return DropdownButtonFormField<String>(
          value: state.sourceId,
          decoration: InputDecoration(labelText: l.txFieldSource),
          items: [
            for (final s in sources)
              DropdownMenuItem(
                value: s.id,
                child: Text(_sourceDisplay(context, s)),
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

class _CategoryField extends ConsumerWidget {
  const _CategoryField({required this.state, required this.onPicked});
  final TransactionFormState state;
  final ValueChanged<String?> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final async = ref.watch(allCategoriesProvider);
    return async.when(
      data: (all) {
        final filtered = all.where((c) => c.type == state.type).toList();
        if (filtered.isEmpty) {
          return _ReadOnlyTile(
            label: l.txFieldCategory,
            value: l.txEmptyCategory,
          );
        }
        // 当前选中项不属于当前类型时清空
        final valid = state.categoryId != null &&
            filtered.any((c) => c.id == state.categoryId);
        return DropdownButtonFormField<String>(
          value: valid ? state.categoryId : null,
          decoration: InputDecoration(labelText: l.txFieldCategory),
          items: [
            for (final c in filtered)
              DropdownMenuItem(
                value: c.id,
                child: Text(_categoryDisplay(context, c)),
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

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onPicked});
  final DateTime value;
  final ValueChanged<DateTime?> onPicked;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: l.txFieldDate),
        child: Text(
          '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
          style: AppTypography.sm,
        ),
      ),
    );
  }
}

class _TagsField extends ConsumerWidget {
  const _TagsField({required this.state, required this.onToggle});
  final TransactionFormState state;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allTagsProvider);
    return async.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.txFieldTags,
              style: AppTypography.xs.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: AppSpacing.x2),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                for (final t in tags)
                  FilterChip(
                    label: Text(_tagDisplay(context, t)),
                    selected: state.tagIds.contains(t.id),
                    onSelected: (_) => onToggle(t.id),
                  ),
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

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(value, style: AppTypography.sm),
    );
  }
}

String _categoryDisplay(BuildContext context, Category c) {
  final localized = resolveDefaultName(AppL10n.of(context), c.nameKey);
  return localized ?? c.name;
}

String _sourceDisplay(BuildContext context, Source s) {
  final localized = resolveDefaultName(AppL10n.of(context), s.nameKey);
  return localized ?? s.name;
}

String _tagDisplay(BuildContext context, Tag t) {
  final localized = resolveDefaultName(AppL10n.of(context), t.nameKey);
  return localized ?? t.name;
}
