import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_harbor_app_local/features/settings/application/default_currency_provider.dart';
import 'package:spend_harbor_app_local/shared/providers/preferences_provider.dart';

void main() {
  test('默认 CAD', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);
    expect(c.read(defaultCurrencyProvider), 'CAD');
  });

  test('set 持久化 + 不支持币种被忽略', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);

    await c.read(defaultCurrencyProvider.notifier).set('JPY');
    expect(c.read(defaultCurrencyProvider), 'JPY');
    expect(prefs.getString('app.defaultCurrency'), 'JPY');

    await c.read(defaultCurrencyProvider.notifier).set('XYZ');
    expect(c.read(defaultCurrencyProvider), 'JPY');
  });

  test('启动时读取已存在值', () async {
    SharedPreferences.setMockInitialValues({'app.defaultCurrency': 'EUR'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);
    expect(c.read(defaultCurrencyProvider), 'EUR');
  });

  test('已存在值不支持时落回 CAD', () async {
    SharedPreferences.setMockInitialValues({'app.defaultCurrency': 'ZZZ'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);
    expect(c.read(defaultCurrencyProvider), 'CAD');
  });
}
