import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/providers/preferences_provider.dart';

const _kPickedKey = 'tx.lastTransactedOn'; // YYYY-MM-DD
const _kSubmittedAtKey = 'tx.lastSubmittedAt'; // ISO-8601 wall clock

/// 上一次新建交易的「用户选的日期 + 实际提交的 wall-clock 时间」。
/// 用于"同日内沿用上次日期、跨天重置为今天"的默认日期策略。
class LastTransactionEntry {
  const LastTransactionEntry({required this.picked, required this.submittedAt});

  final DateTime picked; // 仅日期部分有意义
  final DateTime submittedAt; // 触发提交时的 wall-clock
}

class LastTransactedOnController extends StateNotifier<LastTransactionEntry?> {
  LastTransactedOnController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static LastTransactionEntry? _load(SharedPreferences p) {
    final pickedIso = p.getString(_kPickedKey);
    final submittedIso = p.getString(_kSubmittedAtKey);
    if (pickedIso == null || submittedIso == null) return null;
    final picked = DateTime.tryParse(pickedIso);
    final submittedAt = DateTime.tryParse(submittedIso);
    if (picked == null || submittedAt == null) return null;
    return LastTransactionEntry(picked: picked, submittedAt: submittedAt);
  }

  Future<void> set(DateTime picked, {DateTime? submittedAt}) async {
    final at = submittedAt ?? DateTime.now();
    final pickedIso = '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    state = LastTransactionEntry(picked: picked, submittedAt: at);
    await _prefs.setString(_kPickedKey, pickedIso);
    await _prefs.setString(_kSubmittedAtKey, at.toIso8601String());
  }
}

final lastTransactedOnProvider =
    StateNotifierProvider<LastTransactedOnController, LastTransactionEntry?>(
  (ref) => LastTransactedOnController(ref.watch(sharedPreferencesProvider)),
);
