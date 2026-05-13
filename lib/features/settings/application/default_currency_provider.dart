import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/value_objects/currency.dart';
import '../../../shared/providers/preferences_provider.dart';

const _kKey = 'app.defaultCurrency';

class DefaultCurrencyController extends StateNotifier<String> {
  DefaultCurrencyController(this._prefs)
      : super(_load(_prefs));

  final SharedPreferences _prefs;

  static String _load(SharedPreferences p) {
    final raw = p.getString(_kKey);
    if (raw != null && Currency.isSupported(raw)) return raw;
    return 'CAD';
  }

  Future<void> set(String code) async {
    if (!Currency.isSupported(code)) return;
    state = code;
    await _prefs.setString(_kKey, code);
  }
}

final defaultCurrencyProvider =
    StateNotifierProvider<DefaultCurrencyController, String>(
  (ref) => DefaultCurrencyController(ref.watch(sharedPreferencesProvider)),
);
