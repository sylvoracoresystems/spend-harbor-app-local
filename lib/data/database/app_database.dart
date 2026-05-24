import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/enums/budget_period.dart';
import '../../domain/enums/budget_scope.dart';
import '../../domain/enums/transaction_type.dart';
import '../daos/budget_dao.dart';
import '../daos/category_dao.dart';
import '../daos/source_dao.dart';
import '../daos/tag_dao.dart';
import '../daos/transaction_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Tags,
    Sources,
    Budgets,
    Transactions,
    TransactionTags,
  ],
  daos: [
    CategoryDao,
    TagDao,
    SourceDao,
    BudgetDao,
    TransactionDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试场景下注入内存数据库。
  AppDatabase.forTesting(super.executor);

  /// 当任何 [tables] 里的列 / 约束 / 索引变更时必须 +1，并实现 [MigrationStrategy]。
  /// 当前 schema 处于 v1（首发版本），未实现 onUpgrade。
  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'spend_harbor');
  }
}
