import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import 'database_provider.dart';

final eventListProvider =
    AsyncNotifierProvider<EventListNotifier, List<Event>>(
  EventListNotifier.new,
);

class EventListNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() =>
      ref.read(eventRepositoryProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(
      await ref.read(eventRepositoryProvider).getAll(),
    );
  }

  Future<int> add(Event event) async {
    final id = await ref.read(eventRepositoryProvider).insert(event);
    await refresh();
    return id;
  }

  Future<void> updateEvent(Event event) async {
    await ref.read(eventRepositoryProvider).update(event);
    await refresh();
  }

  Future<bool> delete(int id) async {
    final count =
        await ref.read(eventRepositoryProvider).getRecordCount(id);
    if (count > 0) return false;
    await ref.read(eventRepositoryProvider).delete(id);
    await refresh();
    return true;
  }

  Future<void> reorder(List<Event> events) async {
    await ref.read(eventRepositoryProvider).updateSortOrders(events);
    await refresh();
  }
}
