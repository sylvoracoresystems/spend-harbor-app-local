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
