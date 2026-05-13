import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/budget_period.dart';
import 'package:spend_harbor_app_local/domain/enums/budget_scope.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/data_io/application/backup_serializer.dart';

void main() {
  final now = DateTime(2026, 5, 13, 12, 30);

  BackupSnapshot sample() => BackupSnapshot(
        categories: [
          Category(
            id: 'c1',
            name: 'Food',
            type: TransactionType.expense,
            icon: 'utensils',
            color: '#f97316',
            isDefault: true,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        tags: [
          Tag(
            id: 't1',
            name: 'Work',
            color: '#0ea5e9',
            isDefault: false,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        sources: [
          Source(
            id: 's1',
            name: 'Cash',
            icon: 'wallet',
            color: '#10b981',
            currency: 'CAD',
            isDefault: true,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        budgets: [
          Budget(
            id: 'b1',
            period: BudgetPeriod.month,
            scope: BudgetScope.total,
            amountCents: 50000,
            currency: 'CAD',
            startsOn: '2026-05-01',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        transactions: [
          Transaction(
            id: 'tx1',
            amountCents: 1234,
            currency: 'CAD',
            type: TransactionType.expense,
            categoryId: 'c1',
            sourceId: 's1',
            transactedOn: '2026-05-13',
            note: 'lunch',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        transactionTags: const [
          TransactionTag(transactionId: 'tx1', tagId: 't1'),
        ],
      );

  test('encode → decode round-trip 保持等价', () {
    final s = sample();
    final body = encodeBackup(s);
    final back = decodeBackup(body);

    expect(back.categories.length, 1);
    expect(back.categories.first.id, 'c1');
    expect(back.tags.first.name, 'Work');
    expect(back.sources.first.currency, 'CAD');
    expect(back.budgets.first.period, BudgetPeriod.month);
    expect(back.transactions.first.amountCents, 1234);
    expect(back.transactions.first.note, 'lunch');
    expect(back.transactionTags.first.transactionId, 'tx1');
  });

  test('版本不匹配 → BackupVersionException', () {
    final body = encodeBackup(sample());
    final bumped = body.replaceFirst(
      '"schemaVersion":1',
      '"schemaVersion":99',
    );
    expect(
      () => decodeBackup(bumped),
      throwsA(isA<BackupVersionException>()),
    );
  });

  test('缺 schemaVersion → FormatException', () {
    expect(
      () => decodeBackup('{"categories":[]}'),
      throwsFormatException,
    );
  });
}
