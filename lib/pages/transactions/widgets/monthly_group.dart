import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/icon_map.dart';
import '../../../models/record.dart';
import '../../../widgets/amount_text.dart';

class MonthlyGroup extends StatelessWidget {
  final String monthKey; // yyyy-MM
  final List<GiftRecord> records;
  final void Function(GiftRecord record) onEdit;
  final void Function(GiftRecord record) onDelete;

  const MonthlyGroup({
    super.key,
    required this.monthKey,
    required this.records,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            monthKey,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
        ...records.map((r) => _RecordTile(
              record: r,
              onEdit: () => onEdit(r),
              onDelete: () => onDelete(r),
            )),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final GiftRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordTile({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(record.recordDate);
    return ListTile(
      leading: CircleAvatar(
        child: Icon(getEventIcon(record.eventIcon)),
      ),
      title: Text(record.contactName ?? ''),
      subtitle: Text(
        '${record.eventName ?? ''} · ${DateFormat('MM-dd').format(date)}',
      ),
      trailing: AmountText(amount: record.amount, isIncome: record.isIncome),
      onLongPress: () => _showActions(context),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('修改'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
