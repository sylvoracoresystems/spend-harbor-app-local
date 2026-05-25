import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../shared/utils/hex_color.dart';
import '../../../shared/utils/synced_text_controller.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/transaction_type_toggle.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/tag_usage_provider.dart';
import '../application/transaction_form_controller.dart';

// 整页拆为多个 part 以便维护，私有类（_Header / _CategoryGrid 等）跨文件共享。
part 'transaction_form/header.dart';
part 'transaction_form/amount_currency_date.dart';
part 'transaction_form/category_grid.dart';
part 'transaction_form/tag_section.dart';
part 'transaction_form/footer.dart';

/// 交易表单：金额/币种/日期/类别/标签/来源/备注一站式编辑。
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

/// 持有金额/备注/标签搜索三个 TextController，及 UI 局部态（展开/字段错误）。
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
    final isEditing = widget.editId != null;
    _amountCtrl = syncedTextController(
      ref: ref,
      provider: _provider(),
      selector: (s) => s.amountInput,
      watch: isEditing,
    );
    _noteCtrl = syncedTextController(
      ref: ref,
      provider: _provider(),
      selector: (s) => s.note,
      watch: isEditing,
    );
    _tagSearchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _tagSearchCtrl.dispose();
    super.dispose();
  }

  AutoDisposeStateNotifierProvider<
    TransactionFormController,
    TransactionFormState
  >
  _provider() => transactionFormControllerProvider(widget.editId);

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
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
                        show: _fieldError ==
                                TransactionFormError.amountRequired ||
                            _fieldError == TransactionFormError.amountInvalid ||
                            _fieldError ==
                                TransactionFormError.currencyRequired,
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
                        show: _fieldError ==
                            TransactionFormError.categoryRequired,
                        message: l.txErrCategoryRequired,
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      _TagsSection(
                        selectedIds: state.tagIds,
                        query: _tagQuery,
                        expanded: _tagsExpanded,
                        searchCtrl: _tagSearchCtrl,
                        onQueryChanged: (q) =>
                            setState(() => _tagQuery = q),
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
                      _NoteField(
                        controller: _noteCtrl,
                        onChanged: notifier.setNote,
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      _SourceDropdown(
                        selected: state.sourceId,
                        onPicked: (id, cur) =>
                            notifier.setSource(id, sourceCurrency: cur),
                      ),
                      _ErrorIfAny(
                        show: _fieldError ==
                            TransactionFormError.sourceRequired,
                        message: l.txErrSourceRequired,
                      ),
                      const SizedBox(height: AppSpacing.x6),
                    ],
                  ),
                ),
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
    final ok = await showConfirmDialog(
      context,
      title: l.txDeleteConfirmTitle,
      body: l.txDeleteConfirmBody,
    );
    if (!ok) return;
    await notifier.delete();
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
