import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../shared/widgets/transaction_type_toggle.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/tag_usage_provider.dart';
import '../application/transaction_form_controller.dart';

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({super.key, this.editId});

  /// 为 null 时是新建。
  final String? editId;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

const double _kFieldHeight = 44.0;

const InputBorder _kNoBorder = InputBorder.none;

InputDecoration _flatDecoration({
  required String? hint,
  required TextStyle? hintStyle,
}) {
  return InputDecoration(
    isCollapsed: true,
    filled: false,
    fillColor: Colors.transparent,
    contentPadding: EdgeInsets.zero,
    border: _kNoBorder,
    enabledBorder: _kNoBorder,
    focusedBorder: _kNoBorder,
    disabledBorder: _kNoBorder,
    errorBorder: _kNoBorder,
    focusedErrorBorder: _kNoBorder,
    counterText: '',
    hintText: hint,
    hintStyle: hintStyle,
  );
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _tagSearchCtrl;
  String _tagQuery = '';
  bool _tagsExpanded = false;
  TransactionFormError? _fieldError;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
    _tagSearchCtrl = TextEditingController();
    final initial = ref.read(_provider());
    _amountCtrl.text = initial.amountInput;
    _noteCtrl.text = initial.note;
    if (widget.editId != null) {
      ref.listenManual<TransactionFormState>(_provider(), (prev, next) {
        if (prev?.amountInput != next.amountInput) {
          _amountCtrl.text = next.amountInput;
        }
        if (prev?.note != next.note) _noteCtrl.text = next.note;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _tagSearchCtrl.dispose();
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

    return Scaffold(
      backgroundColor: c.bgMint,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: state.isEditing
                  ? l.editTransactionTitle
                  : l.newTransactionTitle,
              showDelete: state.isEditing,
              onBack: () => Navigator.of(context).pop(),
              onDelete: state.submitting
                  ? null
                  : () => _confirmDelete(context, notifier),
              onSettings: state.submitting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      context.go('/settings');
                    },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x3,
                  AppSpacing.x4,
                  AppSpacing.x3,
                ),
                children: [
                  TransactionTypeToggle(
                    value: state.type,
                    onChanged: notifier.setType,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _AmountAndCurrencyRow(
                    amountCtrl: _amountCtrl,
                    currency: state.currency,
                    onAmount: notifier.setAmount,
                    onCurrency: notifier.setCurrency,
                  ),
                  _ErrorIfAny(
                    show: _fieldError == TransactionFormError.amountRequired ||
                        _fieldError == TransactionFormError.amountInvalid ||
                        _fieldError == TransactionFormError.currencyRequired,
                    message: _fieldError == null
                        ? ''
                        : _messageFor(l, _fieldError!),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _DateRow(
                    value: state.date ?? DateTime.now(),
                    onPicked: notifier.setDate,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _CategoryGrid(
                    type: state.type,
                    selected: state.categoryId,
                    onPicked: notifier.setCategory,
                  ),
                  _ErrorIfAny(
                    show:
                        _fieldError == TransactionFormError.categoryRequired,
                    message: l.txErrCategoryRequired,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _TagsSection(
                    selectedIds: state.tagIds,
                    query: _tagQuery,
                    expanded: _tagsExpanded,
                    searchCtrl: _tagSearchCtrl,
                    onQueryChanged: (q) => setState(() => _tagQuery = q),
                    onToggleExpand: () =>
                        setState(() => _tagsExpanded = !_tagsExpanded),
                    onToggleTag: (id) {
                      final ok = notifier.toggleTag(id);
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l.txTagLimitReached),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _NoteField(controller: _noteCtrl, onChanged: notifier.setNote),
                  const SizedBox(height: AppSpacing.x3),
                  _SourceDropdown(
                    selected: state.sourceId,
                    onPicked: (id, cur) =>
                        notifier.setSource(id, sourceCurrency: cur),
                  ),
                  _ErrorIfAny(
                    show: _fieldError == TransactionFormError.sourceRequired,
                    message: l.txErrSourceRequired,
                  ),
                  const SizedBox(height: AppSpacing.x6),
                ],
              ),
            ),
            _BottomBar(
              submitting: state.submitting,
              onCancel: () => Navigator.of(context).pop(),
              onSave: () async {
                final err = notifier.validate();
                setState(() => _fieldError = err);
                if (err != null) return;
                final ok = await notifier.submit();
                if (ok && context.mounted) Navigator.of(context).pop(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _messageFor(AppL10n l, TransactionFormError e) {
    return switch (e) {
      TransactionFormError.amountRequired => l.txErrAmountRequired,
      TransactionFormError.amountInvalid => l.txErrAmountInvalid,
      TransactionFormError.categoryRequired => l.txErrCategoryRequired,
      TransactionFormError.sourceRequired => l.txErrSourceRequired,
      TransactionFormError.currencyRequired => l.txErrCurrencyRequired,
      TransactionFormError.tagLimitExceeded => l.txTagLimitReached,
    };
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

// ---------- Header ----------

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.showDelete,
    required this.onBack,
    this.onDelete,
    this.onSettings,
  });

  final String title;
  final bool showDelete;
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSoft)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(LucideIcons.chevronLeft),
            color: c.textPrimary,
            iconSize: 22,
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.base.copyWith(
                fontWeight: AppTypography.weightSemibold,
                color: c.textPrimary,
              ),
            ),
          ),
          if (showDelete)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(LucideIcons.trash2),
              color: c.expense,
              iconSize: 20,
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSettings,
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.mintTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.settings,
                  size: 18,
                  color: c.action,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Type segmented ----------

// ---------- Amount + currency ----------

class _AmountAndCurrencyRow extends StatelessWidget {
  const _AmountAndCurrencyRow({
    required this.amountCtrl,
    required this.currency,
    required this.onAmount,
    required this.onCurrency,
  });

  final TextEditingController amountCtrl;
  final String? currency;
  final ValueChanged<String> onAmount;
  final ValueChanged<String> onCurrency;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = AppL10n.of(context);
    final amountStyle = AppTypography.lg.copyWith(
      fontWeight: AppTypography.weightSemibold,
      fontFeatures: AppTypography.monoFeatures,
      color: c.textPrimary,
    );
    return Row(
      children: [
        Expanded(
          child: _OutlinedBox(
            height: _kFieldHeight,
            child: TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: amountStyle,
              decoration: _flatDecoration(
                hint: l.txAmountPlaceholder,
                hintStyle: amountStyle.copyWith(color: c.textHint),
              ),
              onChanged: onAmount,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        SizedBox(
          width: 96,
          child: _OutlinedBox(
            height: _kFieldHeight,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3, vertical: 0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: currency,
                isDense: true,
                icon: Icon(LucideIcons.chevronDown,
                    size: 16, color: c.textMuted),
                style: AppTypography.sm.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: c.textPrimary,
                ),
                items: [
                  for (final cur in Currency.all)
                    DropdownMenuItem(value: cur.code, child: Text(cur.code)),
                ],
                onChanged: (v) {
                  if (v != null) onCurrency(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlinedBox extends StatelessWidget {
  const _OutlinedBox({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3, vertical: AppSpacing.x2),
    this.height,
  });
  final Widget child;
  final EdgeInsets padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: height,
      padding: padding,
      alignment: height != null ? Alignment.centerLeft : null,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: AppRadius.brXl,
      ),
      child: child,
    );
  }
}

// ---------- Date + Yesterday/Today ----------

class _DateRow extends StatelessWidget {
  const _DateRow({required this.value, required this.onPicked});
  final DateTime value;
  final ValueChanged<DateTime?> onPicked;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);
    final valueD = DateTime(value.year, value.month, value.day);
    final yesterday = todayD.subtract(const Duration(days: 1));
    final isYesterday = valueD == yesterday;
    final quickLabel = isYesterday ? l.dayToday : l.dayYesterday;
    final quickTarget = isYesterday ? todayD : yesterday;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: AppRadius.brXl,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2000),
                lastDate:
                    DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (picked != null) onPicked(picked);
            },
            child: _OutlinedBox(
              height: _kFieldHeight,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${value.year.toString().padLeft(4, '0')}/'
                      '${value.month.toString().padLeft(2, '0')}/'
                      '${value.day.toString().padLeft(2, '0')}',
                      style: AppTypography.sm.copyWith(color: c.textPrimary),
                    ),
                  ),
                  Icon(LucideIcons.calendar, size: 16, color: c.textMuted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        InkWell(
          borderRadius: AppRadius.brXl,
          onTap: () => onPicked(quickTarget),
          child: _OutlinedBox(
            height: _kFieldHeight,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
            child: Center(
              child: Text(
                quickLabel,
                style: AppTypography.sm.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: c.textBody,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Category grid ----------

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
            child: Text(l.txEmptyCategory,
                style: AppTypography.sm.copyWith(color: c.textMuted)),
          );
        }
        const crossCount = 4;
        const spacing = AppSpacing.x2;
        const aspectRatio = 1.05;
        const maxVisibleRows = 3;
        final rows = (filtered.length / crossCount).ceil();
        final visibleRows = rows.clamp(1, maxVisibleRows);

        return LayoutBuilder(
          builder: (ctx, cons) {
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
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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
          height: 88, child: Center(child: CircularProgressIndicator())),
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
    final iconColor = _hexToColor(cat.color);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.x1),
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

// ---------- Tags section ----------

class _TagsSection extends ConsumerWidget {
  const _TagsSection({
    required this.selectedIds,
    required this.query,
    required this.expanded,
    required this.searchCtrl,
    required this.onQueryChanged,
    required this.onToggleExpand,
    required this.onToggleTag,
  });

  final Set<String> selectedIds;
  final String query;
  final bool expanded;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onToggleTag;

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
        final visible = showAll
            ? filtered
            : filtered.take(collapsedLimit).toList();
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
                child: Text(
                  l.txTagNoMatch,
                  style:
                      AppTypography.sm.copyWith(color: c.textMuted),
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
              horizontal: AppSpacing.x2 + 2, vertical: 4),
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
            horizontal: AppSpacing.x3, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brFull,
          border: Border.all(
            color: c.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.xs.copyWith(color: c.textMuted),
        ),
      ),
    );
  }
}

// ---------- Note ----------

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = AppL10n.of(context);
    return _OutlinedBox(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3, vertical: AppSpacing.x2 + 2),
      child: TextField(
        controller: controller,
        maxLines: 2,
        maxLength: 500,
        style: AppTypography.sm.copyWith(color: c.textPrimary),
        decoration: _flatDecoration(
          hint: l.txNoteOptional,
          hintStyle: AppTypography.sm.copyWith(color: c.textHint),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ---------- Source dropdown ----------

class _SourceDropdown extends ConsumerWidget {
  const _SourceDropdown({required this.selected, required this.onPicked});

  final String? selected;
  final void Function(String? id, String? currency) onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allSourcesProvider);
    return async.when(
      data: (sources) {
        if (sources.isEmpty) {
          return _OutlinedBox(
            child: Text(l.txEmptySource,
                style: AppTypography.sm.copyWith(color: c.textMuted)),
          );
        }
        return _OutlinedBox(
          height: _kFieldHeight,
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: selected,
              hint: Text(
                l.txSourcePlaceholder,
                style: AppTypography.sm.copyWith(color: c.textHint),
              ),
              icon: Icon(LucideIcons.chevronDown,
                  size: 16, color: c.textMuted),
              style: AppTypography.sm.copyWith(color: c.textPrimary),
              items: [
                for (final s in sources)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      '${_sourceDisplay(context, s)} (${s.currency})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) {
                  onPicked(null, null);
                  return;
                }
                final src = sources.firstWhere((s) => s.id == v);
                onPicked(v, src.currency);
              },
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
    );
  }
}

// ---------- Bottom bar ----------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.submitting,
    required this.onCancel,
    required this.onSave,
  });
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: submitting ? null : onCancel,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.x3),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
                side: BorderSide(color: c.border),
                foregroundColor: c.textBody,
              ),
              child: Text(l.txCancel),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: FilledButton(
              onPressed: submitting ? null : onSave,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.x3),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
                backgroundColor: c.action,
              ),
              child: Text(
                submitting ? '...' : l.txSave,
                style: AppTypography.sm.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Error helper ----------

class _ErrorIfAny extends StatelessWidget {
  const _ErrorIfAny({required this.show, required this.message});
  final bool show;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x1),
      child: Text(
        message,
        style: AppTypography.xs.copyWith(color: c.expense),
      ),
    );
  }
}

// ---------- Helpers ----------

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

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
