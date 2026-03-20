import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/icon_map.dart';
import '../../models/contact.dart';
import '../../providers/contact_providers.dart';
import '../../providers/record_providers.dart';
import '../../widgets/amount_text.dart';

class ContactDetailPage extends ConsumerWidget {
  final Contact contact;

  const ContactDetailPage({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(contactRecordsProvider(contact.id!));

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteContact(context, ref),
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('暂无往来记录', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          double totalIn = 0, totalOut = 0;
          for (final r in records) {
            if (r.isIncome) {
              totalIn += r.amount;
            } else {
              totalOut += r.amount;
            }
          }
          final balance = totalIn - totalOut;

          return Column(
            children: [
              // 顶部汇总
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: '收礼', amount: totalIn, color: Colors.green),
                      _StatItem(label: '随礼', amount: totalOut, color: Colors.red),
                      _StatItem(
                        label: '差额',
                        amount: balance.abs(),
                        color: balance >= 0 ? Colors.green : Colors.red,
                        prefix: balance > 0
                            ? '我欠他 '
                            : balance < 0
                                ? '他欠我 '
                                : '',
                      ),
                    ],
                  ),
                ),
              ),
              // 历史流水列表
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (_, i) {
                    final r = records[i];
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(r.recordDate);
                    return ListTile(
                      leading:
                          CircleAvatar(child: Icon(getEventIcon(r.eventIcon))),
                      title: Text(r.eventName ?? ''),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(date) +
                          (r.note != null && r.note!.isNotEmpty
                              ? ' · ${r.note}'
                              : '')),
                      trailing: AmountText(
                          amount: r.amount, isIncome: r.isIncome),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Future<void> _deleteContact(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除联系人将同时删除其所有往来记录，确定继续吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(contactListProvider.notifier).delete(contact.id!);
      ref.invalidate(recordListProvider);
      ref.invalidate(contactWithBalanceProvider);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String prefix;

  const _StatItem({
    required this.label,
    required this.amount,
    required this.color,
    this.prefix = '',
  });

  String _fmt(double v) =>
      '¥${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          '$prefix${_fmt(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
