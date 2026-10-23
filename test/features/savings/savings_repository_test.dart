import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/core/errors/app_exception.dart';
import 'package:lifemate/features/savings/data/savings_repository.dart';
import 'package:lifemate/features/savings/domain/savings_goal.dart';

void main() {
  const uid = 'u1';
  late FakeFirebaseFirestore db;
  late SavingsRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = SavingsRepository(firestore: db);
  });

  // fake_cloud_firestore's transactions start their writes without
  // awaiting them (real Firestore commits before runTransaction returns),
  // so let those pending writes finish before reading back.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  Future<SavingsGoal> load(String id) async {
    await settle();
    return (await repo.watchOne(uid, id).first)!;
  }
  Future<List<SavingsContribution>> history(String id) =>
      repo.watchContributions(uid, id).first;

  const laptop =
      SavingsGoal(name: 'Laptop', currency: 'USD', targetMinor: 80000);

  test('creating with a starting amount records it as a contribution',
      () async {
    final id = await repo.create(uid, laptop, startingAmountMinor: 10000);
    expect((await load(id)).savedMinor, 10000);
    final h = await history(id);
    expect(h.single.amountMinor, 10000);
    expect(h.single.note, 'Starting amount');
  });

  test('deposits and withdrawals keep total and history consistent',
      () async {
    final id = await repo.create(uid, laptop);
    await repo.addContribution(uid, id, amountMinor: 5000);
    await settle();
    await repo.addContribution(uid, id, amountMinor: 2550);
    await settle();
    await repo.addContribution(uid, id, amountMinor: -1000, note: 'Repair');

    final goal = await load(id);
    final sum = (await history(id)).fold(0, (s, c) => s + c.amountMinor);
    expect(goal.savedMinor, 6550);
    expect(sum, goal.savedMinor);
  });

  test('cannot withdraw more than saved', () async {
    final id = await repo.create(uid, laptop, startingAmountMinor: 1000);
    expect(
      () => repo.addContribution(uid, id, amountMinor: -1001),
      throwsA(isA<ValidationException>()),
    );
    expect((await load(id)).savedMinor, 1000);
  });

  test('deleting a contribution reverses it', () async {
    final id = await repo.create(uid, laptop);
    await repo.addContribution(uid, id, amountMinor: 3000);
    await settle();
    final c = (await history(id)).single;
    await repo.deleteContribution(uid, id, c.id);
    expect((await load(id)).savedMinor, 0);
    expect(await history(id), isEmpty);
  });

  test('deleting a goal removes its contributions', () async {
    final id = await repo.create(uid, laptop, startingAmountMinor: 500);
    await repo.delete(uid, id);
    expect(await repo.watchOne(uid, id).first, isNull);
    final left = await db
        .collection('users/$uid/savingsGoals/$id/contributions')
        .get();
    expect(left.docs, isEmpty);
  });

  test('progress maths uses integers', () {
    const g = SavingsGoal(
        name: 'x', currency: 'USD', targetMinor: 300, savedMinor: 299);
    expect(g.percent, 99); // never rounds up to 100% early
    expect(g.remainingMinor, 1);
    expect(g.isTargetReached, isFalse);
    expect(g.copyWithSaved(300).isTargetReached, isTrue);
  });

  test('ordinary income is not savings: only explicit contributions count',
      () async {
    final id = await repo.create(uid, laptop);
    await db.collection('users/$uid/transactions').add({
      'type': 'income',
      'amountMinorUnits': 100000,
    });
    expect((await load(id)).savedMinor, 0);
  });
}

extension on SavingsGoal {
  SavingsGoal copyWithSaved(int saved) => SavingsGoal(
        name: name,
        currency: currency,
        targetMinor: targetMinor,
        savedMinor: saved,
      );
}
