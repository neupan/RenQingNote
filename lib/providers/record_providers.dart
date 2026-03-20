import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/logger.dart';
import '../models/record.dart';
import 'database_provider.dart';

final recordListProvider =
    AsyncNotifierProvider<RecordListNotifier, List<GiftRecord>>(
  RecordListNotifier.new,
);

class RecordListNotifier extends AsyncNotifier<List<GiftRecord>> {
  @override
  Future<List<GiftRecord>> build() async {
    AppLogger.provider('RecordListNotifier.build: 初始化加载');
    final records = await ref.read(recordRepositoryProvider).getAll();
    AppLogger.provider('RecordListNotifier.build: 加载完成, 共 ${records.length} 条记录');
    return records;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(
      await ref.read(recordRepositoryProvider).getAll(),
    );
  }

  Future<void> add(GiftRecord record) async {
    AppLogger.provider('RecordListNotifier.add: contactId=${record.contactId}, eventId=${record.eventId}, type=${record.type}, amount=${record.amount}');
    await ref.read(recordRepositoryProvider).insert(record);
    await refresh();
    AppLogger.provider('RecordListNotifier.add: 完成, 已刷新列表');
  }

  Future<void> updateRecord(GiftRecord record) async {
    AppLogger.provider('RecordListNotifier.updateRecord: id=${record.id}');
    await ref.read(recordRepositoryProvider).update(record);
    await refresh();
    AppLogger.provider('RecordListNotifier.updateRecord: 完成');
  }

  Future<void> delete(int id) async {
    AppLogger.provider('RecordListNotifier.delete: id=$id');
    await ref.read(recordRepositoryProvider).delete(id);
    await refresh();
    AppLogger.provider('RecordListNotifier.delete: 完成');
  }
}

final yearSummaryProvider =
    FutureProvider.family<Map<int, double>, int>((ref, year) {
  ref.watch(recordListProvider);
  AppLogger.provider('yearSummaryProvider: 加载 $year 年汇总');
  return ref.read(recordRepositoryProvider).getYearSummary(year);
});

final contactRecordsProvider =
    FutureProvider.family<List<GiftRecord>, int>((ref, contactId) {
  ref.watch(recordListProvider);
  AppLogger.provider('contactRecordsProvider: 加载 contactId=$contactId 的流水');
  return ref.read(recordRepositoryProvider).getByContactId(contactId);
});
