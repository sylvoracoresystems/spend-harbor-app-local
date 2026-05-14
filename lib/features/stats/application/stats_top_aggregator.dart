import '../../../data/database/app_database.dart';
import '../../../domain/enums/transaction_type.dart';

class TopCategoryRow {
  const TopCategoryRow({
    required this.categoryId,
    required this.totalCents,
    required this.count,
    required this.tagFrequencies,
  });
  final String categoryId;
  final int totalCents;
  final int count;
  final Map<String, int> tagFrequencies; // tagId -> occurrence count
}

class TopTagCategory {
  const TopTagCategory({required this.categoryId, required this.totalCents});
  final String categoryId;
  final int totalCents;
}

class TopTagRow {
  const TopTagRow({
    required this.tagId,
    required this.totalCents,
    required this.count,
    required this.topCategories,
  });
  final String tagId;
  final int totalCents;
  final int count;
  final List<TopTagCategory> topCategories; // up to 3, desc by amount
}

class UntaggedRow {
  const UntaggedRow({required this.totalCents, required this.count});
  final int totalCents;
  final int count;
}

class TopTagAggregate {
  const TopTagAggregate({required this.rows, required this.untagged});
  final List<TopTagRow> rows;
  final UntaggedRow? untagged;
}

bool _accept(Transaction t, TransactionType type, String currency, String? sourceId) {
  if (t.type != type) return false;
  if (t.currency != currency) return false;
  if (sourceId != null && t.sourceId != sourceId) return false;
  return true;
}

List<TopCategoryRow> aggregateTopByCategory(
  List<Transaction> rows, {
  required TransactionType type,
  required String currency,
  String? sourceId,
  required Map<String, List<String>> tagsByTx,
  required int limit,
}) {
  final totals = <String, int>{};
  final counts = <String, int>{};
  final tagFreq = <String, Map<String, int>>{};
  for (final t in rows) {
    if (!_accept(t, type, currency, sourceId)) continue;
    totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amountCents;
    counts[t.categoryId] = (counts[t.categoryId] ?? 0) + 1;
    final freq = tagFreq.putIfAbsent(t.categoryId, () => <String, int>{});
    for (final tag in tagsByTx[t.id] ?? const <String>[]) {
      freq[tag] = (freq[tag] ?? 0) + 1;
    }
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in entries.take(limit))
      TopCategoryRow(
        categoryId: e.key,
        totalCents: e.value,
        count: counts[e.key]!,
        tagFrequencies: tagFreq[e.key] ?? const {},
      ),
  ];
}

TopTagAggregate aggregateTopByTag(
  List<Transaction> rows, {
  required TransactionType type,
  required String currency,
  String? sourceId,
  required Map<String, List<String>> tagsByTx,
  required int limit,
}) {
  final totals = <String, int>{};
  final counts = <String, int>{};
  final catTotals = <String, Map<String, int>>{};
  var untaggedTotal = 0;
  var untaggedCount = 0;
  for (final t in rows) {
    if (!_accept(t, type, currency, sourceId)) continue;
    final tags = tagsByTx[t.id] ?? const <String>[];
    if (tags.isEmpty) {
      untaggedTotal += t.amountCents;
      untaggedCount += 1;
      continue;
    }
    for (final tag in tags) {
      totals[tag] = (totals[tag] ?? 0) + t.amountCents;
      counts[tag] = (counts[tag] ?? 0) + 1;
      final inner = catTotals.putIfAbsent(tag, () => <String, int>{});
      inner[t.categoryId] = (inner[t.categoryId] ?? 0) + t.amountCents;
    }
  }
  final tagEntries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final outRows = [
    for (final e in tagEntries.take(limit))
      TopTagRow(
        tagId: e.key,
        totalCents: e.value,
        count: counts[e.key]!,
        topCategories: (() {
          final inner = catTotals[e.key]!.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return [
            for (final c in inner.take(3))
              TopTagCategory(categoryId: c.key, totalCents: c.value),
          ];
        })(),
      ),
  ];
  return TopTagAggregate(
    rows: outRows,
    untagged: untaggedCount > 0
        ? UntaggedRow(totalCents: untaggedTotal, count: untaggedCount)
        : null,
  );
}
