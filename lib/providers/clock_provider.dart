import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/date_utils.dart';

/// Emits the current time now, and again just after every local midnight.
///
/// Widgets and providers that depend on "today" (daily limit, today's
/// spending) watch this so they roll over to the new day even if the app
/// stays open overnight without any data changes.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  while (true) {
    final now = DateTime.now();
    yield now;
    final nextMidnight = AppDateUtils.dayOf(now).end;
    await Future<void>.delayed(
      nextMidnight.difference(now) + const Duration(seconds: 1),
    );
  }
});

/// Synchronous "now" for code that cannot wait for [clockProvider].
DateTime watchNow(Ref ref) => ref.watch(clockProvider).value ?? DateTime.now();
