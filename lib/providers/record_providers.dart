import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/record.dart';
import 'database_provider.dart';

final recordListProvider =
    AsyncNotifierProvider<RecordListNotifier, List<GiftRecord>>(
  RecordListNotifier.new,
);

class RecordListNotifier extends AsyncNotifier<List<GiftRecord>> {
  @override
  Future<List<GiftRecord>> build() =>
      ref.read(recordRepositoryProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(
      await ref.read(recordRepositoryProvider).getAll(),
    );
  }

  Future<void> add(GiftRecord record) async {
    await ref.read(recordRepositoryProvider).insert(record);
    await refresh();
    ref.invalidate(yearSummaryProvider);
  }

  Future<void> updateRecord(GiftRecord record) async {
    await ref.read(recordRepositoryProvider).update(record);
    await refresh();
    ref.invalidate(yearSummaryProvider);
  }

  Future<void> delete(int id) async {
    await ref.read(recordRepositoryProvider).delete(id);
    await refresh();
    ref.invalidate(yearSummaryProvider);
  }
}

/// 当前年份的收支汇总
final yearSummaryProvider =
    FutureProvider.family<Map<int, double>, int>((ref, year) {
  ref.watch(recordListProvider);
  return ref.read(recordRepositoryProvider).getYearSummary(year);
});

/// 某联系人的历史流水
final contactRecordsProvider =
    FutureProvider.family<List<GiftRecord>, int>((ref, contactId) {
  ref.watch(recordListProvider);
  return ref.read(recordRepositoryProvider).getByContactId(contactId);
});
