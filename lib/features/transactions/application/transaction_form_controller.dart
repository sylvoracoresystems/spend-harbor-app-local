import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../settings/application/default_currency_provider.dart';
import 'last_transacted_on_provider.dart';

const _uuid = Uuid();

/// 单笔交易最多绑定多少个 tag。
const int kMaxTagsPerTransaction = 5;

/// 交易表单状态。
class TransactionFormState {
  const TransactionFormState({
    this.id,
    this.amountInput = '',
    this.type = TransactionType.expense,
    this.categoryId,
    this.sourceId,
    this.currency,
    this.currencyManuallySet = false,
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

  /// 当前选中的币种（ISO code）。可独立于 source 修改。
  final String? currency;

  /// 用户是否手动改过 currency；若是则切换 source 时不再自动覆盖。
  final bool currencyManuallySet;

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
    Object? currency = _unset,
    bool? currencyManuallySet,
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
      currency: currency == _unset ? this.currency : currency as String?,
      currencyManuallySet: currencyManuallySet ?? this.currencyManuallySet,
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
  currencyRequired,
  tagLimitExceeded,
}

/// 驱动交易新建/编辑：加载、字段更新（金额/类别/标签/来源/日期）、校验与提交。
class TransactionFormController extends StateNotifier<TransactionFormState> {
  TransactionFormController(this._ref, {String? editId})
      : super(_initial(_ref, editId)) {
    if (editId != null) _loadExisting(editId);
  }

  final Ref _ref;

  static TransactionFormState _initial(Ref ref, String? editId) {
    if (editId != null) {
      // 编辑态：先占位 date=null，加载完成后填回。
      return TransactionFormState(id: editId);
    }
    // 新建态：默认日期取上次提交日期或今天；币种取默认币种。
    final lastIso = ref.read(lastTransactedOnProvider);
    DateTime date = DateTime.now();
    if (lastIso != null) {
      final parsed = DateTime.tryParse(lastIso);
      if (parsed != null) date = DateTime(parsed.year, parsed.month, parsed.day);
    }
    final defaultCurrency = ref.read(defaultCurrencyProvider);
    return TransactionFormState(date: date, currency: defaultCurrency);
  }

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
      currency: row.currency,
      currencyManuallySet: true, // 编辑态视为已确定，不被 source 联动覆盖
      date: DateTime.parse(row.transactedOn),
      tagIds: tagIds.toSet(),
      note: row.note ?? '',
    );
  }

  void setAmount(String v) => state = state.copyWith(amountInput: v);

  void setType(TransactionType v) {
    if (v == state.type) return;
    // 切换 type 时清空 category（避免分类不匹配）。
    state = state.copyWith(type: v, categoryId: null);
  }

  void setCategory(String? id) => state = state.copyWith(categoryId: id);

  /// 选择 source 时，若用户尚未手动改过 currency，则同步为 source 的币种。
  void setSource(String? id, {String? sourceCurrency}) {
    if (state.currencyManuallySet || sourceCurrency == null) {
      state = state.copyWith(sourceId: id);
    } else {
      state = state.copyWith(sourceId: id, currency: sourceCurrency);
    }
  }

  void setCurrency(String code) {
    state = state.copyWith(currency: code, currencyManuallySet: true);
  }

  void setDate(DateTime? d) => state = state.copyWith(date: d);
  void setNote(String v) => state = state.copyWith(note: v);

  /// 切换 tag；返回 true 表示该次操作有效，false 表示因为达到上限被拒绝。
  bool toggleTag(String id) {
    final next = {...state.tagIds};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (next.length >= kMaxTagsPerTransaction) return false;
      next.add(id);
    }
    state = state.copyWith(tagIds: next);
    return true;
  }

  /// 校验当前状态；返回首个错误或 null。
  TransactionFormError? validate() {
    final raw = state.amountInput.trim();
    if (raw.isEmpty) return TransactionFormError.amountRequired;
    if (state.amountCents == null) return TransactionFormError.amountInvalid;
    if (state.categoryId == null) return TransactionFormError.categoryRequired;
    if (state.sourceId == null) return TransactionFormError.sourceRequired;
    if (state.currency == null) return TransactionFormError.currencyRequired;
    return null;
  }

  /// 提交：写入交易 + 标签关联。返回 true 表示已成功。
  Future<bool> submit() async {
    if (validate() != null) return false;
    if (state.submitting) return false;
    state = state.copyWith(submitting: true);
    try {
      final dao = _ref.read(transactionDaoProvider);
      final date = state.date ?? DateTime.now();
      final transactedOn =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final companion = TransactionsCompanion(
        id: Value(state.id ?? _uuid.v4()),
        amountCents: Value(state.amountCents!),
        currency: Value(state.currency!),
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
        // 仅新建态持久化日期，避免编辑态污染。
        await _ref.read(lastTransactedOnProvider.notifier).set(date);
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
