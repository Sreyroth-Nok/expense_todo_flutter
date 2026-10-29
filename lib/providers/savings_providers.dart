import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_repository.dart';
import '../services/savings_repository.dart';
import '../models/savings_goal.dart';

final savingsGoalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(savingsRepositoryProvider).watchAll(uid);
});

final savingsGoalByIdProvider =
    StreamProvider.autoDispose.family<SavingsGoal?, String>((ref, id) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(savingsRepositoryProvider).watchOne(uid, id);
});

final contributionsProvider = StreamProvider.autoDispose
    .family<List<SavingsContribution>, String>((ref, goalId) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(savingsRepositoryProvider).watchContributions(uid, goalId);
});
