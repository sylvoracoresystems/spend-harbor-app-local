import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../shared/icons/icon_registry.dart';

const _uuid = Uuid();

class CategoryFormState {
  const CategoryFormState({
    this.id,
    this.name = '',
    this.type = TransactionType.expense,
    this.icon = 'tag',
    this.color = '#10b981',
    this.submitting = false,
  });

  final String? id;
  final String name;
  final TransactionType type;
  final String icon;
  final String color;
  final bool submitting;

  bool get isEditing => id != null;

  CategoryFormState copyWith({
    String? name,
    TransactionType? type,
    String? icon,
    String? color,
    bool? submitting,
  }) => CategoryFormState(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    submitting: submitting ?? this.submitting,
  );
}

enum CategoryFormError { nameRequired, nameDuplicate }

class CategoryFormController extends StateNotifier<CategoryFormState> {
  CategoryFormController(
    this._ref, {
    String? editId,
    TransactionType? initialType,
  }) : super(
         CategoryFormState(
           id: editId,
           type: initialType ?? TransactionType.expense,
         ),
       ) {
    if (editId != null) _load(editId);
  }

  final Ref _ref;

  Future<void> _load(String id) async {
    final dao = _ref.read(categoryDaoProvider);
    final row = await dao.findById(id);
    if (row == null) return;
    state = CategoryFormState(
      id: row.id,
      name: row.name,
      type: row.type,
      icon: row.icon,
      color: row.color,
    );
  }

  void setName(String v) => state = state.copyWith(name: v);
  void setType(TransactionType v) => state = state.copyWith(type: v);
  void setIcon(String v) => state = state.copyWith(icon: v);
  void setColor(String v) => state = state.copyWith(color: v);

  /// 同步校验。`existsName` 是异步的，在 [submit] 内做。
  CategoryFormError? validateSync() {
    if (state.name.trim().isEmpty) return CategoryFormError.nameRequired;
    return null;
  }

  /// 返回 null 表示成功；非 null 是错误码。
  Future<CategoryFormError?> submit() async {
    final syncErr = validateSync();
    if (syncErr != null) return syncErr;
    if (state.submitting) return null;
    state = state.copyWith(submitting: true);
    try {
      final dao = _ref.read(categoryDaoProvider);
      final dup = await dao.existsName(
        state.name.trim(),
        state.type,
        excludeId: state.id,
      );
      if (dup) return CategoryFormError.nameDuplicate;

      if (state.isEditing) {
        // 仅覆盖可编辑字段；createdAt / isDefault / nameKey 保持原值。
        await dao.updateName(
          id: state.id!,
          name: state.name.trim(),
          type: state.type,
          icon: state.icon,
          color: state.color,
        );
      } else {
        await dao.insertCategory(
          CategoriesCompanion.insert(
            id: _uuid.v4(),
            name: state.name.trim(),
            type: state.type,
            icon: state.icon,
            color: state.color,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) state = state.copyWith(submitting: false);
    }
  }

  Future<void> delete() async {
    if (!state.isEditing) return;
    await _ref.read(categoryDaoProvider).softDelete(state.id!);
  }
}

final categoryFormControllerProvider = StateNotifierProvider.autoDispose.family<
  CategoryFormController,
  CategoryFormState,
  (String?, TransactionType?)
>(
  (ref, args) =>
      CategoryFormController(ref, editId: args.$1, initialType: args.$2),
);

/// 监听某 type 的存活分类（CategoriesPage / 表单选择器都可复用）。
final categoriesByTypeProvider =
    StreamProvider.family<List<Category>, TransactionType>((ref, type) {
      return ref.watch(categoryDaoProvider).watchByType(type);
    });

/// 默认调色板（供 UI 引用，避免直接依赖 shared/icons）。
const defaultIconKey = 'tag';
const defaultColorHex = '#10b981';
const fallbackPalette = kPaletteHex;
