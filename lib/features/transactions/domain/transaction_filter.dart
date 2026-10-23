import '../../../core/utils/date_utils.dart';
import 'finance_transaction.dart';

/// Describes which transactions the history screen should show.
///
/// [range] and [type] are applied by the Firestore query (server side).
/// [categoryId] and [search] are applied in memory on the already
/// date-limited results, which keeps the number of Firestore indexes small.
///
/// Implements == and hashCode so it can be used as a Riverpod family key.
class TransactionFilter {
  const TransactionFilter({
    this.range,
    this.type,
    this.categoryId,
    this.search = '',
  });

  /// Half-open date range; null means "all time".
  final DateRange? range;
  final TransactionType? type;
  final String? categoryId;
  final String search;

  /// The part of the filter that needs a new Firestore query.
  TransactionFilter get queryPart => TransactionFilter(range: range, type: type);

  bool matches(FinanceTransaction tx) {
    if (range != null && !range!.contains(tx.date)) return false;
    if (type != null && tx.type != type) return false;
    if (categoryId != null && tx.categoryId != categoryId) return false;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty &&
        !tx.description.toLowerCase().contains(q) &&
        !tx.categoryName.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }

  TransactionFilter copyWith({
    DateRange? range,
    bool clearRange = false,
    TransactionType? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategory = false,
    String? search,
  }) =>
      TransactionFilter(
        range: clearRange ? null : (range ?? this.range),
        type: clearType ? null : (type ?? this.type),
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        search: search ?? this.search,
      );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.range == range &&
      other.type == type &&
      other.categoryId == categoryId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(range, type, categoryId, search);
}
