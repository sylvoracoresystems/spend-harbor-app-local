import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/providers/preferences_provider.dart';

const _kKey = 'tx.lastTransactedOn';

/// 记录用户最近一次新建交易使用的日期（YYYY-MM-DD），
/// 用于下次进入新建表单时默认填入，方便连续补录历史交易。
class LastTransactedOnController extends StateNotifier<String?> {
  LastTransactedOnController(this._prefs) : super(_prefs.getString(_kKey));

  final SharedPreferences _prefs;

  Future<void> set(DateTime date) async {
    final iso = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    state = iso;
    await _prefs.setString(_kKey, iso);
  }
}

final lastTransactedOnProvider =
    StateNotifierProvider<LastTransactedOnController, String?>(
  (ref) => LastTransactedOnController(ref.watch(sharedPreferencesProvider)),
);
