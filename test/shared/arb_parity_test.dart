import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ARB 一致性回归：en / zh 必须 key 完全对齐，且无空值。
/// Phase 7 国际化全量回归基线测试——任何漏翻译会在 CI 立刻挂红。
void main() {
  late Map<String, dynamic> en;
  late Map<String, dynamic> zh;

  setUpAll(() {
    en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    zh = jsonDecode(File('lib/l10n/app_zh.arb').readAsStringSync())
        as Map<String, dynamic>;
  });

  // 排除元数据：@@locale + @keyName 描述项
  Set<String> userKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  test('en / zh ARB key 集合完全一致', () {
    final ek = userKeys(en);
    final zk = userKeys(zh);
    final onlyEn = ek.difference(zk);
    final onlyZh = zk.difference(ek);
    expect(onlyEn, isEmpty, reason: 'zh 缺失这些 key: $onlyEn');
    expect(onlyZh, isEmpty, reason: 'en 缺失这些 key: $onlyZh');
  });

  test('en / zh 所有翻译值非空', () {
    for (final k in userKeys(en)) {
      expect((en[k] as String).trim(), isNotEmpty, reason: 'en[$k] 为空');
    }
    for (final k in userKeys(zh)) {
      expect((zh[k] as String).trim(), isNotEmpty, reason: 'zh[$k] 为空');
    }
  });

  test('en / zh placeholder 集合一致（防 {name} 漏写）', () {
    final placeholderRe = RegExp(r'\{(\w+)\}');
    for (final k in userKeys(en)) {
      final enPh = placeholderRe
          .allMatches(en[k] as String)
          .map((m) => m.group(1))
          .toSet();
      final zhPh = placeholderRe
          .allMatches(zh[k] as String)
          .map((m) => m.group(1))
          .toSet();
      expect(zhPh, enPh, reason: 'key=$k placeholder 不一致');
    }
  });
}
