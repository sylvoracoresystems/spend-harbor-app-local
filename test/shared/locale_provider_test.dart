import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_harbor_app_local/shared/providers/locale_provider.dart';
import 'package:spend_harbor_app_local/shared/providers/preferences_provider.dart';

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  });

  tearDown(() => container.dispose());

  test('默认 null = 跟随系统', () {
    expect(container.read(localeControllerProvider), isNull);
  });

  test('setLocale 持久化到 prefs', () async {
    await container
        .read(localeControllerProvider.notifier)
        .setLocale(const Locale('zh'));
    expect(container.read(localeControllerProvider), const Locale('zh'));
    expect(prefs.getString('app.locale'), 'zh');
  });

  test('setLocale(null) 清空 prefs', () async {
    await container
        .read(localeControllerProvider.notifier)
        .setLocale(const Locale('zh'));
    await container
        .read(localeControllerProvider.notifier)
        .setLocale(null);
    expect(container.read(localeControllerProvider), isNull);
    expect(prefs.getString('app.locale'), isNull);
  });

  test('启动时读取已存在的 locale', () async {
    SharedPreferences.setMockInitialValues({'app.locale': 'zh'});
    final prefs2 = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs2),
    ]);
    expect(c.read(localeControllerProvider), const Locale('zh'));
    c.dispose();
  });
}
