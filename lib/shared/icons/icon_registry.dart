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
/// 排成 10 列网格；29 色 + 末尾一个自定义 `+` 槽，刚好 3 行。
const List<String> kPaletteHex = <String>[
  // row 1: 绿—青系
  '#10b981', '#34d399', '#059669', '#84cc16', '#22c55e',
  '#14b8a6', '#06b6d4', '#0ea5e9', '#0284c7', '#0d9488',
  // row 2: 蓝—紫—粉
  '#3b82f6', '#6366f1', '#4f46e5', '#8b5cf6', '#a855f7',
  '#d946ef', '#ec4899', '#db2777', '#f43f5e', '#e11d48',
  // row 3: 红—橙—黄—灰（末尾留给自定义 + 按钮）
  '#ef4444', '#dc2626', '#f97316', '#ea580c', '#f59e0b',
  '#facc15', '#eab308', '#64748b', '#475569',
];
