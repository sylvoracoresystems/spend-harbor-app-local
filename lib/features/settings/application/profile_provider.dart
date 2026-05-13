import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/providers/preferences_provider.dart';

const _kNicknameKey = 'profile.nickname';

/// 个人昵称（空字符串 = 未设置）。
class ProfileController extends StateNotifier<String> {
  ProfileController(this._prefs)
      : super(_prefs.getString(_kNicknameKey) ?? '');

  final SharedPreferences _prefs;

  Future<void> setNickname(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_kNicknameKey);
    } else {
      await _prefs.setString(_kNicknameKey, trimmed);
    }
    state = trimmed;
  }
}

final profileNicknameProvider =
    StateNotifierProvider<ProfileController, String>((ref) {
  return ProfileController(ref.watch(sharedPreferencesProvider));
});

/// 从昵称生成 2 字符头像 initials（中文取首字，西文取首字母大写）。
String initialsFor(String nickname) {
  final trimmed = nickname.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  // 用 runes 处理 emoji / 中文等多字节字符
  String firstChar(String s) => String.fromCharCode(s.runes.first);
  if (parts.length >= 2) {
    return (firstChar(parts[0]) + firstChar(parts[1])).toUpperCase();
  }
  final runes = parts[0].runes.toList();
  final take = runes.take(2).toList();
  return String.fromCharCodes(take).toUpperCase();
}
