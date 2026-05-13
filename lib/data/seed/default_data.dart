import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums/transaction_type.dart';
import '../database/app_database.dart';

/// 支持的 seed 语言：与 PRODUCT_SPEC §9.1 一致。
enum SeedLocale { enUS, zhCN }

const _uuid = Uuid();

/// 首次启动时调用：若数据库为空，注入默认分类/标签/来源。
///
/// 幂等：若已存在任何默认 Category，则直接返回，不重复插入。
Future<void> seedDefaultData(
  AppDatabase db, {
  required SeedLocale locale,
  String defaultCurrency = 'CAD',
}) async {
  final existing = await (db.select(db.categories)
        ..where((t) => t.isDefault.equals(true))
        ..limit(1))
      .getSingleOrNull();
  if (existing != null) return;

  final cats = _defaultCategories(locale);
  final tags = _defaultTags(locale);
  final sources = _defaultSources(locale, defaultCurrency);

  await db.batch((b) {
    b.insertAll(db.categories, cats);
    b.insertAll(db.tags, tags);
    b.insertAll(db.sources, sources);
  });
}

// ============ Categories ============

List<CategoriesCompanion> _defaultCategories(SeedLocale locale) {
  const expenseSeeds = <_CatSeed>[
    _CatSeed('catFood', 'Food', '餐饮', 'utensils', '#f97316'),
    _CatSeed('catTransport', 'Transport', '交通', 'car', '#0ea5e9'),
    _CatSeed('catShopping', 'Shopping', '购物', 'shopping-bag', '#ec4899'),
    _CatSeed('catEntertainment', 'Entertainment', '娱乐', 'music', '#8b5cf6'),
    _CatSeed('catHome', 'Home', '居家', 'home', '#10b981'),
    _CatSeed('catMedical', 'Medical', '医疗', 'heart-pulse', '#ef4444'),
    _CatSeed('catEducation', 'Education', '教育', 'graduation-cap', '#6366f1'),
    _CatSeed('catTelecom', 'Telecom', '通讯', 'smartphone', '#14b8a6'),
    _CatSeed('catTravel', 'Travel', '旅行', 'plane', '#f59e0b'),
    _CatSeed('catOther', 'Other', '其他', 'box', '#64748b'),
  ];
  const incomeSeeds = <_CatSeed>[
    _CatSeed('catSalary', 'Salary', '工资', 'briefcase', '#10b981'),
    _CatSeed('catBonus', 'Bonus', '奖金', 'gift', '#f59e0b'),
    _CatSeed('catInvestment', 'Investment', '投资', 'trending-up', '#0ea5e9'),
    _CatSeed('catOtherIncome', 'Other Income', '其他收入', 'circle-plus',
        '#64748b'),
  ];

  final result = <CategoriesCompanion>[];
  var order = 0;
  for (final s in expenseSeeds) {
    result.add(CategoriesCompanion.insert(
      id: _uuid.v4(),
      name: s.nameFor(locale),
      nameKey: Value(s.key),
      type: TransactionType.expense,
      icon: s.icon,
      color: s.color,
      isDefault: const Value(true),
      sortOrder: Value(order++),
    ));
  }
  order = 0;
  for (final s in incomeSeeds) {
    result.add(CategoriesCompanion.insert(
      id: _uuid.v4(),
      name: s.nameFor(locale),
      nameKey: Value(s.key),
      type: TransactionType.income,
      icon: s.icon,
      color: s.color,
      isDefault: const Value(true),
      sortOrder: Value(order++),
    ));
  }
  return result;
}

// ============ Tags ============

List<TagsCompanion> _defaultTags(SeedLocale locale) {
  const seeds = <_TagSeed>[
    _TagSeed('tagWork', 'Work', '工作', '#0ea5e9'),
    _TagSeed('tagPersonal', 'Personal', '私人', '#8b5cf6'),
    _TagSeed('tagFamily', 'Family', '家庭', '#ec4899'),
    _TagSeed('tagImportant', 'Important', '重要', '#ef4444'),
    _TagSeed('tagReimburse', 'Reimburse', '可报销', '#10b981'),
  ];
  var order = 0;
  return seeds
      .map((s) => TagsCompanion.insert(
            id: _uuid.v4(),
            name: s.nameFor(locale),
            nameKey: Value(s.key),
            color: s.color,
            isDefault: const Value(true),
            sortOrder: Value(order++),
          ))
      .toList();
}

// ============ Sources ============

List<SourcesCompanion> _defaultSources(
  SeedLocale locale,
  String defaultCurrency,
) {
  const seeds = <_SrcSeed>[
    _SrcSeed('srcCash', 'Cash', '现金', 'wallet', '#10b981'),
  ];
  var order = 0;
  return seeds
      .map((s) => SourcesCompanion.insert(
            id: _uuid.v4(),
            name: s.nameFor(locale),
            nameKey: Value(s.key),
            icon: s.icon,
            color: s.color,
            currency: defaultCurrency,
            isDefault: const Value(true),
            sortOrder: Value(order++),
          ))
      .toList();
}

// ============ Seed descriptors ============

class _CatSeed {
  const _CatSeed(this.key, this.en, this.zh, this.icon, this.color);
  final String key;
  final String en;
  final String zh;
  final String icon;
  final String color;
  String nameFor(SeedLocale locale) =>
      locale == SeedLocale.zhCN ? zh : en;
}

class _TagSeed {
  const _TagSeed(this.key, this.en, this.zh, this.color);
  final String key;
  final String en;
  final String zh;
  final String color;
  String nameFor(SeedLocale locale) =>
      locale == SeedLocale.zhCN ? zh : en;
}

class _SrcSeed {
  const _SrcSeed(this.key, this.en, this.zh, this.icon, this.color);
  final String key;
  final String en;
  final String zh;
  final String icon;
  final String color;
  String nameFor(SeedLocale locale) =>
      locale == SeedLocale.zhCN ? zh : en;
}
