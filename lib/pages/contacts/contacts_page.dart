import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contact.dart';
import '../../providers/contact_providers.dart';
import 'contact_detail_page.dart';

class ContactsPage extends ConsumerWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(contactWithBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('人脉')),
      body: dataAsync.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('暂无联系人', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final grouped = _groupByPinyin(rows);
          final keys = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (_, i) {
              final letter = keys[i];
              final items = grouped[letter]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LetterHeader(letter: letter),
                  ...items.map((row) => _ContactTile(row: row)),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByPinyin(
      List<Map<String, dynamic>> rows) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final pinyin = (row['pinyin'] as String?) ?? '';
      final letter =
          pinyin.isNotEmpty ? pinyin[0].toUpperCase() : '#';
      final key = RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#';
      map.putIfAbsent(key, () => []).add(row);
    }
    return map;
  }
}

class _LetterHeader extends StatelessWidget {
  final String letter;
  const _LetterHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(letter,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Map<String, dynamic> row;
  const _ContactTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final contact = Contact.fromMap(row);
    final totalIn = (row['total_in'] as num?)?.toDouble() ?? 0;
    final totalOut = (row['total_out'] as num?)?.toDouble() ?? 0;
    final balance = totalIn - totalOut;

    Widget balanceChip;
    if (balance > 0) {
      balanceChip = _BalanceLabel(
        text: '我欠他 ¥${_fmt(balance)}',
        color: Colors.green,
      );
    } else if (balance < 0) {
      balanceChip = _BalanceLabel(
        text: '他欠我 ¥${_fmt(-balance)}',
        color: Colors.red,
      );
    } else if (totalIn == 0 && totalOut == 0) {
      balanceChip = const _BalanceLabel(text: '无往来', color: Colors.grey);
    } else {
      balanceChip = const _BalanceLabel(text: '已平账', color: Colors.grey);
    }

    return ListTile(
      leading: CircleAvatar(child: Text(contact.name[0])),
      title: Text(contact.name),
      subtitle: contact.memo != null && contact.memo!.isNotEmpty
          ? Text(contact.memo!)
          : null,
      trailing: balanceChip,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ContactDetailPage(contact: contact),
        ));
      },
    );
  }

  String _fmt(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
}

class _BalanceLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _BalanceLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
