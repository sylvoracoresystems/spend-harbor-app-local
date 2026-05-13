import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';

const _uuid = Uuid();

class TagFormState {
  const TagFormState({
    this.id,
    this.name = '',
    this.color = '#10b981',
    this.submitting = false,
  });

  final String? id;
  final String name;
  final String color;
  final bool submitting;

  bool get isEditing => id != null;

  TagFormState copyWith({
    String? name,
    String? color,
    bool? submitting,
  }) =>
      TagFormState(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        submitting: submitting ?? this.submitting,
      );
}

enum TagFormError { nameRequired, nameDuplicate }

class TagFormController extends StateNotifier<TagFormState> {
  TagFormController(this._ref, {String? editId})
      : super(TagFormState(id: editId)) {
    if (editId != null) _load(editId);
  }

  final Ref _ref;

  Future<void> _load(String id) async {
    final row = await _ref.read(tagDaoProvider).findById(id);
    if (row == null) return;
    state = TagFormState(id: row.id, name: row.name, color: row.color);
  }

  void setName(String v) => state = state.copyWith(name: v);
  void setColor(String v) => state = state.copyWith(color: v);

  TagFormError? validateSync() {
    if (state.name.trim().isEmpty) return TagFormError.nameRequired;
    return null;
  }

  Future<TagFormError?> submit() async {
    final syncErr = validateSync();
    if (syncErr != null) return syncErr;
    if (state.submitting) return null;
    state = state.copyWith(submitting: true);
    try {
      final dao = _ref.read(tagDaoProvider);
      final dup =
          await dao.existsName(state.name.trim(), excludeId: state.id);
      if (dup) return TagFormError.nameDuplicate;

      if (state.isEditing) {
        await dao.updateName(
          id: state.id!,
          name: state.name.trim(),
          color: state.color,
        );
      } else {
        await dao.insertTag(TagsCompanion.insert(
          id: _uuid.v4(),
          name: state.name.trim(),
          color: state.color,
          nameKey: const Value(null),
        ));
      }
      return null;
    } finally {
      if (mounted) state = state.copyWith(submitting: false);
    }
  }

  Future<void> delete() async {
    if (!state.isEditing) return;
    await _ref.read(tagDaoProvider).softDelete(state.id!);
  }
}

final tagFormControllerProvider = StateNotifierProvider.autoDispose
    .family<TagFormController, TagFormState, String?>(
  (ref, editId) => TagFormController(ref, editId: editId),
);
