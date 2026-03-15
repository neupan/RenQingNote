import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/record.dart';
import '../../providers/record_providers.dart';
import '../../providers/contact_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/event_providers.dart';
import '../add_record/add_record_page.dart';
import 'widgets/year_summary_card.dart';
import 'widgets/monthly_group.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('人情记')),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return Column(
              children: [
                const YearSummaryCard(),
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('暂无记录，点击 + 开始记账',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final grouped = _groupByMonth(records);
          return ListView(
            children: [
              const YearSummaryCard(),
              ...grouped.entries.map((entry) => MonthlyGroup(
                    monthKey: entry.key,
                    records: entry.value,
                    onEdit: (r) => _editRecord(context, ref, r),
                    onDelete: (r) => _deleteRecord(context, ref, r),
                  )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Map<String, List<GiftRecord>> _groupByMonth(List<GiftRecord> records) {
    final map = <String, List<GiftRecord>>{};
    for (final r in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.recordDate);
      final key = DateFormat('yyyy-MM').format(date);
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  Future<void> _editRecord(
      BuildContext context, WidgetRef ref, GiftRecord record) async {
    final contactRepo = ref.read(contactRepositoryProvider);
    final contact = await contactRepo.getById(record.contactId);
    final eventsState = ref.read(eventListProvider);
    final events = eventsState.value ?? [];
    final event = events.where((e) => e.id == record.eventId).firstOrNull;

    if (!context.mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddRecordPage(
          editRecord: record,
          editContact: contact,
          editEvent: event,
        ),
      ),
    );
    if (result == true) {
      ref.invalidate(contactWithBalanceProvider);
    }
  }

  Future<void> _deleteRecord(
      BuildContext context, WidgetRef ref, GiftRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(recordListProvider.notifier).delete(record.id!);
      ref.invalidate(contactWithBalanceProvider);
    }
  }
}
