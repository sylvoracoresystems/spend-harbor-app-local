import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';

const _uuid = Uuid();

class SourceFormState {
  const SourceFormState({
    this.id,
    this.name = '',
    this.icon = 'wallet',
    this.color = '#10b981',
    this.currency = 'CAD',
    this.submitting = false,
  });

  final String? id;
  final String name;
  final String icon;
  final String color;
  final String currency;
  final bool submitting;

  bool get isEditing => id != null;

  SourceFormState copyWith({
    String? name,
    String? icon,
    String? color,
    String? currency,
    bool? submitting,
  }) =>
      SourceFormState(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        currency: currency ?? this.currency,
        submitting: submitting ?? this.submitting,
      );
}

enum SourceFormError { nameRequired, nameDuplicate }

class SourceFormController extends StateNotifier<SourceFormState> {
  SourceFormController(this._ref, {String? editId})
      : super(SourceFormState(id: editId)) {
    if (editId != null) _load(editId);
  }

  final Ref _ref;

  Future<void> _load(String id) async {
    final row = await _ref.read(sourceDaoProvider).findById(id);
    if (row == null) return;
    state = SourceFormState(
      id: row.id,
      name: row.name,
      icon: row.icon,
      color: row.color,
      currency: row.currency,
    );
  }

  void setName(String v) => state = state.copyWith(name: v);
  void setIcon(String v) => state = state.copyWith(icon: v);
  void setColor(String v) => state = state.copyWith(color: v);
  void setCurrency(String v) => state = state.copyWith(currency: v);

  SourceFormError? validateSync() {
    if (state.name.trim().isEmpty) return SourceFormError.nameRequired;
    return null;
  }

  Future<SourceFormError?> submit() async {
    final syncErr = validateSync();
    if (syncErr != null) return syncErr;
    if (state.submitting) return null;
    state = state.copyWith(submitting: true);
    try {
      final dao = _ref.read(sourceDaoProvider);
      final dup =
          await dao.existsName(state.name.trim(), excludeId: state.id);
      if (dup) return SourceFormError.nameDuplicate;

      if (state.isEditing) {
        await dao.updateName(
          id: state.id!,
          name: state.name.trim(),
          icon: state.icon,
          color: state.color,
          currency: state.currency,
        );
      } else {
        await dao.insertSource(SourcesCompanion.insert(
          id: _uuid.v4(),
          name: state.name.trim(),
          icon: state.icon,
          color: state.color,
          currency: state.currency,
        ));
      }
      return null;
    } finally {
      if (mounted) state = state.copyWith(submitting: false);
    }
  }

  Future<void> delete() async {
    if (!state.isEditing) return;
    await _ref.read(sourceDaoProvider).softDelete(state.id!);
  }
}

final sourceFormControllerProvider = StateNotifierProvider.autoDispose
    .family<SourceFormController, SourceFormState, String?>(
  (ref, editId) => SourceFormController(ref, editId: editId),
);
