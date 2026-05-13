import 'dart:ui' show Locale;

import 'default_data.dart';

/// 把平台 [Locale] 映射到 [SeedLocale]；非中文一律落回英文。
SeedLocale seedLocaleFromPlatform(Locale locale) {
  return locale.languageCode == 'zh' ? SeedLocale.zhCN : SeedLocale.enUS;
}
