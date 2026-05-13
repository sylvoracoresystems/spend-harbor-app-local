import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../domain/enums/budget_period.dart';
import '../../../domain/enums/budget_scope.dart';
import '../../settings/application/default_currency_provider.dart';
import 'budget_period_alignment.dart';

const _uuid = Uuid();

class BudgetFormState {
  const BudgetFormState({
    this.id,
    this.period = BudgetPeriod.month,
    this.scope = BudgetScope.total,
    this.categoryId,
    this.amountInput = '',
    this.currency = 'CAD',
    this.startsOn,
    this.submitting = false,
  });

  final String? id;
  final BudgetPeriod period;
  final BudgetScope scope;
  final String? categoryId;
  final String amountInput;
  final String currency;

  /// 用户可手动调整的起始日；为 null 时提交时用 [alignToPeriodStart(now)]。
  final DateTime? startsOn;

  final bool submitting;

  bool get isEditing => id != null;

  int? get amountCents {
    final raw = amountInput.trim();
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) return null;
    return (parsed * 100).round();
  }

  BudgetFormState copyWith({
    BudgetPeriod? period,
    BudgetScope? scope,
    Object? categoryId = _unset,
    String? amountInput,
    String? currency,
    Object? startsOn = _unset,
    bool? submitting,
  }) =>
      BudgetFormState(
        id: id,
        period: period ?? this.period,
        scope: scope ?? this.scope,
        categoryId:
            categoryId == _unset ? this.categoryId : categoryId as String?,
        amountInput: amountInput ?? this.amountInput,
        currency: currency ?? this.currency,
        startsOn: startsOn == _unset ? this.startsOn : startsOn as DateTime?,
        submitting: submitting ?? this.submitting,
      );
}

const _unset = Object();

enum BudgetFormError { amountInvalid, categoryRequired }

class BudgetFormController extends StateNotifier<BudgetFormState> {
  BudgetFormController(this._ref, {String? editId})
      : super(BudgetFormState(
          id: editId,
          currency: editId == null ? _readDefault(_ref) : 'CAD',
        )) {
    if (editId != null) _load(editId);
  }

  static String _readDefault(Ref ref) {
    try {
      return ref.read(defaultCurrencyProvider);
    } catch (_) {
      return 'CAD';
    }
  }

  final Ref _ref;

  Future<void> _load(String id) async {
    final row = await _ref.read(budgetDaoProvider).findById(id);
    if (row == null) return;
    state = BudgetFormState(
      id: row.id,
      period: row.period,
      scope: row.scope,
      categoryId: row.categoryId,
      amountInput: (row.amountCents / 100).toStringAsFixed(2),
      currency: row.currency,
      startsOn: DateTime.parse(row.startsOn),
    );
  }

  void setPeriod(BudgetPeriod v) {
    // 周期变化时自动重新对齐 startsOn
    final base = state.startsOn ?? DateTime.now();
    state = state.copyWith(
      period: v,
      startsOn: alignToPeriodStart(base, v),
    );
  }

  void setScope(BudgetScope v) {
    state = state.copyWith(
      scope: v,
      categoryId: v == BudgetScope.total ? null : state.categoryId,
    );
  }

  void setCategory(String? id) => state = state.copyWith(categoryId: id);
  void setAmount(String v) => state = state.copyWith(amountInput: v);
  void setCurrency(String v) => state = state.copyWith(currency: v);
  void setStartsOn(DateTime d) => state = state.copyWith(startsOn: d);

  BudgetFormError? validate() {
    if (state.amountCents == null) return BudgetFormError.amountInvalid;
    if (state.scope == BudgetScope.category && state.categoryId == null) {
      return BudgetFormError.categoryRequired;
    }
    return null;
  }

  Future<BudgetFormError?> submit() async {
    final err = validate();
    if (err != null) return err;
    if (state.submitting) return null;
    state = state.copyWith(submitting: true);
    try {
      final dao = _ref.read(budgetDaoProvider);
      final start = alignToPeriodStart(
        state.startsOn ?? DateTime.now(),
        state.period,
      );
      final companion = BudgetsCompanion(
        id: Value(state.id ?? _uuid.v4()),
        period: Value(state.period),
        scope: Value(state.scope),
        categoryId: Value(state.categoryId),
        amountCents: Value(state.amountCents!),
        currency: Value(state.currency),
        startsOn: Value(formatIsoDate(start)),
        updatedAt: Value(DateTime.now()),
      );
      if (state.isEditing) {
        await dao.updateBudget(companion);
      } else {
        await dao.insertBudget(companion);
      }
      return null;
    } finally {
      if (mounted) state = state.copyWith(submitting: false);
    }
  }

  Future<void> delete() async {
    if (!state.isEditing) return;
    await _ref.read(budgetDaoProvider).softDelete(state.id!);
  }
}

final budgetFormControllerProvider = StateNotifierProvider.autoDispose
    .family<BudgetFormController, BudgetFormState, String?>(
  (ref, editId) => BudgetFormController(ref, editId: editId),
);

final allBudgetsProvider = StreamProvider<List<Budget>>(
  (ref) => ref.watch(budgetDaoProvider).watchAll(),
);
