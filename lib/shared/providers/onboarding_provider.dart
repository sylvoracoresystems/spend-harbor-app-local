import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_provider.dart';

const _kOnboardingDoneKey = 'onboarding.done';

/// 首次启动标记：`true` 表示已完成 Onboarding。
class OnboardingController extends StateNotifier<bool> {
  OnboardingController(this._prefs)
      : super(_prefs.getBool(_kOnboardingDoneKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> markDone() async {
    await _prefs.setBool(_kOnboardingDoneKey, true);
    state = true;
  }

  Future<void> reset() async {
    await _prefs.remove(_kOnboardingDoneKey);
    state = false;
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingController(prefs);
});
