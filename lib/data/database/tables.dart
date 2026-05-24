/// Drift 表定义。跨表共通约定（不再每张表重复）：
///
/// - **主键**：所有业务表都用 String UUID（[uuid] 包生成），方便备份导入时直接复用 id。
/// - **软删除**：所有 user-facing 表都有 `deletedAt`（含 index），DAO 查询默认 `IS NULL`。
///   物理删除只在 transactions 的 purge / purgeOlderThan 走（保留期满或用户清空回收站）。
/// - **i18n**：种子项有 `nameKey`（对应 ARB key），用户重命名后清空（[name] 接管）。
/// - **金额**：minor units（"分"），int 存储，绝对避免浮点。type 列决定正负方向，
///   amountCents 始终非负。
/// - **日期 vs 时间戳**：业务日期（[Transactions.transactedOn] / [Budgets.startsOn]）
///   存 ISO `YYYY-MM-DD` 字符串便于按月 / 日跨时区聚合；系统戳（createdAt 等）走 DateTime。
/// - **币种**：所有持币列共用 [currencyCheck] 白名单 CHECK；多币种不换算（PRODUCT_SPEC §1）。
/// - **外键**：用 `.references()`，drift 生成 SQL 的 REFERENCES 子句。Taxonomy 软删除
///   不会撤回引用（FK-safe，见 taxonomy_import_controller.dart）。
library;

import 'package:drift/drift.dart';

import '../../domain/enums/budget_period.dart';
import '../../domain/enums/budget_scope.dart';
import '../../domain/enums/transaction_type.dart';

/// 货币 CHECK 约束，硬编码以便 drift codegen 分析。
/// 与 [Currency.all] 保持同步（PRODUCT_SPEC §6.5）。
const String currencyCheck =
    "currency IN ('CAD','USD','CNY','HKD','TWD','JPY','KRW','SGD','AUD','NZD','GBP','EUR','CHF','INR','THB','MYR','PHP','VND')";

/// 分类表（Category）。
@TableIndex(name: 'idx_categories_deleted_at', columns: {#deletedAt})
class Categories extends Table {
  TextColumn get id => text()();

  /// 展示名；默认项可为空（由 [nameKey] 渲染）
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// i18n key，仅默认项有；用户编辑后清空
  TextColumn get nameKey => text().nullable()();

  TextColumn get type => textEnum<TransactionType>()();

  /// 图标名（来自 iconRegistry）
  TextColumn get icon => text()();

  /// 16 进制颜色，如 `#10b981`
  TextColumn get color => text()();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 标签表（Tag）。
@TableIndex(name: 'idx_tags_deleted_at', columns: {#deletedAt})
class Tags extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get nameKey => text().nullable()();
  TextColumn get color => text()();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 来源表（Source / 资金账户 / 支付方式）。
@TableIndex(name: 'idx_sources_deleted_at', columns: {#deletedAt})
class Sources extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get nameKey => text().nullable()();
  TextColumn get icon => text()();
  TextColumn get color => text()();

  /// ISO-4217 货币代码，CHECK 约束限定白名单
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).check(CustomExpression(currencyCheck))();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 预算表（Budget）。
@TableIndex(name: 'idx_budgets_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_budgets_category', columns: {#categoryId})
class Budgets extends Table {
  TextColumn get id => text()();

  TextColumn get period => textEnum<BudgetPeriod>()();
  TextColumn get scope => textEnum<BudgetScope>()();

  /// scope=category 时指向 Categories.id；scope=total 时为 null
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();

  /// 金额（minor units / 「分」），int 存储避免浮点误差
  IntColumn get amountCents => integer()();

  TextColumn get currency =>
      text().withLength(min: 3, max: 3).check(CustomExpression(currencyCheck))();

  /// 周期起点（ISO 日期字符串 YYYY-MM-DD），按 period 对齐
  TextColumn get startsOn => text()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 交易表（Transaction）。
@TableIndex(name: 'idx_transactions_transacted_on', columns: {#transactedOn})
@TableIndex(name: 'idx_transactions_category', columns: {#categoryId})
@TableIndex(name: 'idx_transactions_source', columns: {#sourceId})
@TableIndex(name: 'idx_transactions_deleted_at', columns: {#deletedAt})
class Transactions extends Table {
  TextColumn get id => text()();

  /// 金额 minor units（正数；type 决定正负方向）
  IntColumn get amountCents => integer()();

  TextColumn get currency =>
      text().withLength(min: 3, max: 3).check(CustomExpression(currencyCheck))();

  TextColumn get type => textEnum<TransactionType>()();

  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get sourceId => text().references(Sources, #id)();

  /// 交易发生日期（ISO 日期字符串 YYYY-MM-DD，本地时区解读）
  TextColumn get transactedOn => text()();

  TextColumn get note => text().nullable().withLength(max: 500)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 交易 ↔ 标签 多对多关联表。
@TableIndex(name: 'idx_transaction_tags_tag', columns: {#tagId})
class TransactionTags extends Table {
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, tagId};
}
