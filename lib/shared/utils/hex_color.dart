import 'package:flutter/material.dart';

/// 把 `#RRGGBB` / `RRGGBB` 形式的十六进制色串解析成不透明的 [Color]。
///
/// 数据库里 category / tag / source 的颜色统一以 hex 字符串保存，
/// UI 层需要 [Color] 时调用此扩展，避免在各页面重复定义私有的 `_hexToColor`。
extension HexColor on Color {
  static Color fromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('ff$cleaned', radix: 16));
  }
}
