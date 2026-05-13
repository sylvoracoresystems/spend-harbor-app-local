import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_harbor_app_local/features/settings/application/profile_provider.dart';
import 'package:spend_harbor_app_local/shared/providers/preferences_provider.dart';

void main() {
  group('initialsFor', () {
    test('空 → ?', () {
      expect(initialsFor(''), '?');
      expect(initialsFor('   '), '?');
    });
    test('单词取前两字母大写', () {
      expect(initialsFor('alice'), 'AL');
    });
    test('双词取首字母', () {
      expect(initialsFor('John Doe'), 'JD');
    });
    test('中文取首字', () {
      expect(initialsFor('小明'), '小明');
    });
    test('中文双名取首字 + 第二字', () {
      expect(initialsFor('张三 李四'), '张李');
    });
  });

  test('ProfileController 读写 prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    expect(container.read(profileNicknameProvider), '');
    await container.read(profileNicknameProvider.notifier).setNickname('Lei');
    expect(container.read(profileNicknameProvider), 'Lei');
    expect(prefs.getString('profile.nickname'), 'Lei');

    // 清空 = 移除 key
    await container.read(profileNicknameProvider.notifier).setNickname('');
    expect(prefs.getString('profile.nickname'), isNull);
  });
}
