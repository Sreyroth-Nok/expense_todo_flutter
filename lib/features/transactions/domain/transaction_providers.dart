import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/data/auth_repository.dart';
import '../../spending_limits/data/spending_limit_alert_service.dart';
import '../../spending_limits/domain/limit_alert_policy.dart';
import '../data/category_repository.dart';
import '../data/transaction_repository.dart';
import 'finance_transaction.dart';
import 'transaction_category.dart';
import 'transaction_filter.dart';

// ── Read providers ────────────────────────────────────────────────────────

/// All categories of the signed-in user. Creates the starter categories
/// the first time it runs for an account.
final categoriesProvider = StreamProvider<List<TransactionCategory>>((ref) async* {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    yield const [];
    return;
  }
  final repo = ref.watch(categoryRepositoryProvider);
  try {
    await repo.ensureDefaults(uid);
  } catch (e) {
    // Not fatal: the user can still create categories manually.
    Logger().w('Could not create default categories: $e');
  }
  yield* repo.watchAll(uid);
});

/// Live transactions for the SERVER-SIDE part of a filter (date range and
/// type). Pass `filter.queryPart` and apply `filter.matches` in the UI, so
/// typing in the search box does not open a new Firestore listener.
final transactionQueryProvider = StreamProvider.autoDispose
    .family<List<FinanceTransaction>, TransactionFilter>((ref, filter) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(transactionRepositoryProvider).watch(uid, filter);
});

/// One transaction by id (null if it was deleted).
final transactionByIdProvider = StreamProvider.autoDispose
    .family<FinanceTransaction?, String>((ref, id) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(transactionRepositoryProvider).watchOne(uid, id);
});

// ── Write service ─────────────────────────────────────────────────────────

/// Business logic for changing transactions.
///
/// Every successful add / edit / delete re-checks the spending limits
/// (Phase 3 rule 5) and returns any alerts that fired so the UI can show
/// them. A failing limit check never undoes or blocks the save (rule 11).
class TransactionService {
  TransactionService({
    required TransactionRepository repository,
    required SpendingLimitAlertService alerts,
    required String? Function() currentUid,
  })  : _repository = repository,
        _alerts = alerts,
        _currentUid = currentUid;

  final TransactionRepository _repository;
  final SpendingLimitAlertService _alerts;
  final String? Function() _currentUid;
  final _log = Logger();

  String _requireUid() {
    final uid = _currentUid();
    if (uid == null) {
      throw const AuthException('Please log in again.');
    }
    return uid;
  }

  static void validate(FinanceTransaction tx) {
    if (tx.amountMinor <= 0) {
      throw const ValidationException('Amount must be greater than zero.');
    }
    if (tx.categoryId.isEmpty) {
      throw const ValidationException('Please choose a category.');
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(tx.currency)) {
      throw const ValidationException('Unsupported currency.');
    }
    if (tx.description.length > 200) {
      throw const ValidationException(
          'Description must be 200 characters or fewer.');
    }
  }

  Future<List<LimitAlert>> add(FinanceTransaction tx) async {
    validate(tx);
    final uid = _requireUid();
    await _repository.add(uid, tx);
    return _recheckLimits(uid);
  }

  Future<List<LimitAlert>> update(FinanceTransaction tx) async {
    validate(tx);
    final uid = _requireUid();
    await _repository.update(uid, tx);
    return _recheckLimits(uid);
  }

  Future<List<LimitAlert>> delete(String id) async {
    final uid = _requireUid();
    await _repository.delete(uid, id);
    return _recheckLimits(uid);
  }

  Future<List<LimitAlert>> _recheckLimits(String uid) async {
    try {
      return await _alerts.checkLimits(uid);
    } catch (e) {
      _log.w('Spending-limit check failed: $e');
      return const [];
    }
  }
}

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(
    repository: ref.watch(transactionRepositoryProvider),
    alerts: ref.watch(spendingLimitAlertServiceProvider),
    currentUid: () => ref.read(currentUidProvider),
  );
});
