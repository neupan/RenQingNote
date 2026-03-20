import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/logger.dart';
import '../models/event.dart';
import 'database_provider.dart';

final eventListProvider =
    AsyncNotifierProvider<EventListNotifier, List<Event>>(
  EventListNotifier.new,
);

class EventListNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    AppLogger.provider('EventListNotifier.build: 初始化加载');
    final events = await ref.read(eventRepositoryProvider).getAll();
    AppLogger.provider('EventListNotifier.build: 加载完成, 共 ${events.length} 个事件');
    return events;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(
      await ref.read(eventRepositoryProvider).getAll(),
    );
  }

  Future<int> add(Event event) async {
    AppLogger.provider('EventListNotifier.add: name=${event.name}');
    final id = await ref.read(eventRepositoryProvider).insert(event);
    await refresh();
    AppLogger.provider('EventListNotifier.add: 完成, id=$id');
    return id;
  }

  Future<void> updateEvent(Event event) async {
    AppLogger.provider('EventListNotifier.updateEvent: id=${event.id}, name=${event.name}');
    await ref.read(eventRepositoryProvider).update(event);
    await refresh();
  }

  Future<bool> delete(int id) async {
    AppLogger.provider('EventListNotifier.delete: id=$id, 检查引用...');
    final count =
        await ref.read(eventRepositoryProvider).getRecordCount(id);
    if (count > 0) {
      AppLogger.provider('EventListNotifier.delete: 拒绝, 事件被 $count 条记录引用');
      return false;
    }
    await ref.read(eventRepositoryProvider).delete(id);
    await refresh();
    AppLogger.provider('EventListNotifier.delete: 完成');
    return true;
  }

  Future<void> reorder(List<Event> events) async {
    AppLogger.provider('EventListNotifier.reorder: ${events.length} 个事件');
    await ref.read(eventRepositoryProvider).updateSortOrders(events);
    await refresh();
  }
}
