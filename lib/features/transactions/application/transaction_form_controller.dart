import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../domain/enums/transaction_type.dart';

const _uuid = Uuid();

/// 交易表单状态。
class TransactionFormState {
  const TransactionFormState({
    this.id,
    this.amountInput = '',
    this.type = TransactionType.expense,
    this.categoryId,
    this.sourceId,
    this.date,
    this.tagIds = const <String>{},
    this.note = '',
    this.submitting = false,
  });

  /// 编辑模式下持有原交易 id；新建时为 null。
  final String? id;

  /// 用户输入的字符串（带最多 2 位小数）。
  final String amountInput;

  final TransactionType type;
  final String? categoryId;
  final String? sourceId;
  final DateTime? date;
  final Set<String> tagIds;
  final String note;
  final bool submitting;

  bool get isEditing => id != null;

  /// 把输入字符串解析为 minor units（cents）；无效返回 null。
  int? get amountCents {
    final raw = amountInput.trim();
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) return null;
    return (parsed * 100).round();
  }

  TransactionFormState copyWith({
    String? id,
    String? amountInput,
    TransactionType? type,
    Object? categoryId = _unset,
    Object? sourceId = _unset,
    Object? date = _unset,
    Set<String>? tagIds,
    String? note,
    bool? submitting,
  }) {
    return TransactionFormState(
      id: id ?? this.id,
      amountInput: amountInput ?? this.amountInput,
      type: type ?? this.type,
      categoryId:
          categoryId == _unset ? this.categoryId : categoryId as String?,
      sourceId: sourceId == _unset ? this.sourceId : sourceId as String?,
      date: date == _unset ? this.date : date as DateTime?,
      tagIds: tagIds ?? this.tagIds,
      note: note ?? this.note,
      submitting: submitting ?? this.submitting,
    );
  }
}

const _unset = Object();

/// 表单校验错误（i18n key）。
enum TransactionFormError {
  amountRequired,
  amountInvalid,
  categoryRequired,
  sourceRequired,
}

class TransactionFormController extends StateNotifier<TransactionFormState> {
  TransactionFormController(this._ref, {String? editId})
      : super(TransactionFormState(id: editId, date: DateTime.now())) {
    if (editId != null) _loadExisting(editId);
  }

  final Ref _ref;

  Future<void> _loadExisting(String id) async {
    final dao = _ref.read(transactionDaoProvider);
    final row = await dao.findById(id);
    if (row == null) return;
    final tagIds = await dao.tagIdsOf(id);
    state = state.copyWith(
      amountInput: (row.amountCents / 100).toStringAsFixed(2),
      type: row.type,
      categoryId: row.categoryId,
      sourceId: row.sourceId,
      date: DateTime.parse(row.transactedOn),
      tagIds: tagIds.toSet(),
      note: row.note ?? '',
    );
  }

  void setAmount(String v) => state = state.copyWith(amountInput: v);
  void setType(TransactionType v) => state = state.copyWith(type: v);
  void setCategory(String? id) => state = state.copyWith(categoryId: id);
  void setSource(String? id) => state = state.copyWith(sourceId: id);
  void setDate(DateTime? d) => state = state.copyWith(date: d);
  void setNote(String v) => state = state.copyWith(note: v);

  void toggleTag(String id) {
    final next = {...state.tagIds};
    if (!next.add(id)) next.remove(id);
    state = state.copyWith(tagIds: next);
  }

  /// 校验当前状态；返回首个错误或 null。
  TransactionFormError? validate() {
    final raw = state.amountInput.trim();
    if (raw.isEmpty) return TransactionFormError.amountRequired;
    if (state.amountCents == null) return TransactionFormError.amountInvalid;
    if (state.categoryId == null) return TransactionFormError.categoryRequired;
    if (state.sourceId == null) return TransactionFormError.sourceRequired;
    return null;
  }

  /// 提交：根据来源派生币种，写入交易 + 标签关联。
  /// 返回 true 表示已成功提交。
  Future<bool> submit() async {
    if (validate() != null) return false;
    if (state.submitting) return false;
    state = state.copyWith(submitting: true);
    try {
      final db = _ref.read(appDatabaseProvider);
      final source = await (db.select(db.sources)
            ..where((t) => t.id.equals(state.sourceId!)))
          .getSingle();
      final dao = _ref.read(transactionDaoProvider);
      final date = state.date ?? DateTime.now();
      final transactedOn =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final companion = TransactionsCompanion(
        id: Value(state.id ?? _uuid.v4()),
        amountCents: Value(state.amountCents!),
        currency: Value(source.currency),
        type: Value(state.type),
        categoryId: Value(state.categoryId!),
        sourceId: Value(state.sourceId!),
        transactedOn: Value(transactedOn),
        note: Value(state.note.trim().isEmpty ? null : state.note.trim()),
        updatedAt: Value(DateTime.now()),
      );
      if (state.isEditing) {
        await dao.updateWithTags(companion, state.tagIds.toList());
      } else {
        await dao.insertWithTags(companion, state.tagIds.toList());
      }
      return true;
    } finally {
      if (mounted) state = state.copyWith(submitting: false);
    }
  }

  /// 软删除当前交易（仅编辑模式）。
  Future<void> delete() async {
    if (!state.isEditing) return;
    await _ref.read(transactionDaoProvider).softDelete(state.id!);
  }
}

/// `editId` 为 null 时是新建表单。
final transactionFormControllerProvider = StateNotifierProvider.autoDispose
    .family<TransactionFormController, TransactionFormState, String?>(
  (ref, editId) => TransactionFormController(ref, editId: editId),
);
