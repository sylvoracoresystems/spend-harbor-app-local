import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 分类 / 标签 / 来源可选图标。`key` 与 DB `icon` 字段对应。
///
/// 仅维护一份白名单，便于把符号字符串映射回 [IconData] 渲染。
const Map<String, IconData> kIconRegistry = <String, IconData>{
  'utensils': LucideIcons.utensils,
  'car': LucideIcons.car,
  'shopping-bag': LucideIcons.shoppingBag,
  'music': LucideIcons.music,
  'home': LucideIcons.home,
  'heart-pulse': LucideIcons.heartPulse,
  'graduation-cap': LucideIcons.graduationCap,
  'smartphone': LucideIcons.smartphone,
  'plane': LucideIcons.plane,
  'box': LucideIcons.box,
  'briefcase': LucideIcons.briefcase,
  'gift': LucideIcons.gift,
  'trending-up': LucideIcons.trendingUp,
  'circle-plus': LucideIcons.plusCircle,
  'wallet': LucideIcons.wallet,
  'credit-card': LucideIcons.creditCard,
  'piggy-bank': LucideIcons.piggyBank,
  'banknote': LucideIcons.banknote,
  'coffee': LucideIcons.coffee,
  'gamepad': LucideIcons.gamepad2,
  'book': LucideIcons.book,
  'baby': LucideIcons.baby,
  'paw': LucideIcons.dog,
  'leaf': LucideIcons.leaf,
  'star': LucideIcons.star,
  'tag': LucideIcons.tag,
  'hash': LucideIcons.hash,
};

/// 渲染 [icon] 对应的 [IconData]；找不到时落回 [LucideIcons.tag]。
IconData iconFor(String? key) {
  if (key == null) return LucideIcons.tag;
  return kIconRegistry[key] ?? LucideIcons.tag;
}

/// 推荐配色（与 DESIGN_STANDARDS 调色板对齐）。
const List<String> kPaletteHex = <String>[
  '#10b981', // mint
  '#f97316', // orange
  '#0ea5e9', // sky
  '#ec4899', // pink
  '#8b5cf6', // violet
  '#ef4444', // red
  '#6366f1', // indigo
  '#14b8a6', // teal
  '#f59e0b', // amber
  '#64748b', // slate
];
