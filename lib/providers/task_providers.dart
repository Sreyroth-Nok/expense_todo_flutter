import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_repository.dart';
import '../services/task_repository.dart';
import '../models/planner_task.dart';

final tasksProvider = StreamProvider<List<PlannerTask>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(taskRepositoryProvider).watchAll(uid);
});

final taskByIdProvider =
    StreamProvider.autoDispose.family<PlannerTask?, String>((ref, id) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(taskRepositoryProvider).watchOne(uid, id);
});
