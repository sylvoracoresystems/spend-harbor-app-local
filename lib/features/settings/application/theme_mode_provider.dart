import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/providers/preferences_provider.dart';

const _kThemeModeKey = 'app.themeMode';

ThemeMode _decode(String? raw) {
  switch (raw) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

String _encode(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

/// 持久化亮/暗/跟随系统的主题偏好。
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs)
      : super(_decode(_prefs.getString(_kThemeModeKey)));

  final SharedPreferences _prefs;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeModeKey, _encode(mode));
  }
}

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(sharedPreferencesProvider));
});
