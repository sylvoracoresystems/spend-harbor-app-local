import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_harbor_app_local/features/settings/application/theme_mode_provider.dart';
import 'package:spend_harbor_app_local/shared/providers/preferences_provider.dart';

void main() {
  test('默认 system', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);
    expect(c.read(themeModeControllerProvider), ThemeMode.system);
  });

  test('set 持久化', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);

    await c.read(themeModeControllerProvider.notifier).set(ThemeMode.dark);
    expect(c.read(themeModeControllerProvider), ThemeMode.dark);
    expect(prefs.getString('app.themeMode'), 'dark');
  });

  test('启动时读取已存在值', () async {
    SharedPreferences.setMockInitialValues({'app.themeMode': 'light'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);
    expect(c.read(themeModeControllerProvider), ThemeMode.light);
  });
}
