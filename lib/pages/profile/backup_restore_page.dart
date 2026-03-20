import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart' show CsvEncoder;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/logger.dart';
import '../../providers/database_provider.dart';
import '../../providers/record_providers.dart';
import '../../providers/contact_providers.dart';
import '../../providers/event_providers.dart';

class BackupRestorePage extends ConsumerWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: ListView(
        children: [
          const _SectionHeader(title: '导出'),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('导出 CSV'),
            subtitle: const Text('生成表格文件并分享'),
            onTap: () => _exportCsv(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份数据 (JSON)'),
            subtitle: const Text('导出全部数据到 JSON 文件'),
            onTap: () => _exportJson(context, ref),
          ),
          const Divider(),
          const _SectionHeader(title: '恢复'),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('从 JSON 恢复'),
            subtitle: const Text('选择备份文件覆盖恢复'),
            onTap: () => _importJson(context, ref),
          ),
          const Divider(),
          const _SectionHeader(title: '测试'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('清空所有数据',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('删除全部记录、联系人和事件（保留预设事件）'),
            onTap: () => _clearAllData(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    AppLogger.backup('CSV导出: 开始');
    try {
      final repo = ref.read(recordRepositoryProvider);
      final rows = await repo.getAllForExport();
      if (rows.isEmpty) {
        AppLogger.backup('CSV导出: 无数据');
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('暂无数据可导出')));
        }
        return;
      }

      final csvData = [
        ['姓名', '类型', '金额', '事件', '日期', '备注'],
        ...rows.map((r) {
          final date = DateTime.fromMillisecondsSinceEpoch(r['record_date'] as int);
          return [
            r['contact_name'],
            (r['type'] as int) == 1 ? '收礼' : '随礼',
            (r['amount'] as num).toDouble(),
            r['event_name'],
            DateFormat('yyyy-MM-dd').format(date),
            r['note'] ?? '',
          ];
        }),
      ];

      final csv = const CsvEncoder().convert(csvData);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/renqing_$timestamp.csv');
      await file.writeAsString(csv);
      AppLogger.backup('CSV导出: ${rows.length} 行, 文件=${file.path}');

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (e, stack) {
      AppLogger.error('CSV导出失败', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    AppLogger.backup('JSON备份: 开始');
    try {
      final dbHelper = ref.read(databaseHelperProvider);
      final db = await dbHelper.database;

      final contacts = await db.query('contacts');
      final events = await db.query('events');
      final records = await db.query('records');
      AppLogger.backup('JSON备份: events=${events.length}, contacts=${contacts.length}, records=${records.length}');

      final data = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'events': events,
        'contacts': contacts,
        'records': records,
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/renqing_backup_$timestamp.json');
      await file.writeAsString(json);
      AppLogger.backup('JSON备份: 文件=${file.path}');

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (e, stack) {
      AppLogger.error('JSON备份失败', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('备份失败: $e')));
      }
    }
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    AppLogger.backup('清空数据: 请求确认');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('将删除全部记录、联系人和自定义事件，预设事件会保留。此操作不可撤销！'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认清空',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) {
      AppLogger.backup('清空数据: 用户取消');
      return;
    }

    try {
      final dbHelper = ref.read(databaseHelperProvider);
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        await txn.delete('records');
        await txn.delete('contacts');
        await txn.delete('events', where: 'is_preset = 0');
      });

      AppLogger.backup('清空数据: 数据库已清空, 刷新 Provider');
      ref.invalidate(eventListProvider);
      ref.invalidate(contactListProvider);
      ref.invalidate(recordListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有数据已清空')),
        );
      }
    } catch (e, stack) {
      AppLogger.error('清空数据失败', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('清空失败: $e')));
      }
    }
  }

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    AppLogger.backup('JSON恢复: 开始');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('警告'),
        content: const Text('恢复操作将覆盖当前所有数据，确定继续吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定恢复', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) {
      AppLogger.backup('JSON恢复: 用户取消');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) {
        AppLogger.backup('JSON恢复: 未选择文件');
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) return;
      AppLogger.backup('JSON恢复: 文件=$filePath');

      final content = await File(filePath).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      AppLogger.backup('JSON恢复: version=${data['version']}');

      if (data['version'] != 1) {
        AppLogger.backup('JSON恢复: 不支持的版本 ${data['version']}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('不支持的备份版本')));
        }
        return;
      }

      final dbHelper = ref.read(databaseHelperProvider);
      final db = await dbHelper.database;

      final events = data['events'] as List<dynamic>? ?? [];
      final contacts = data['contacts'] as List<dynamic>? ?? [];
      final records = data['records'] as List<dynamic>? ?? [];
      AppLogger.backup('JSON恢复: 解析到 events=${events.length}, contacts=${contacts.length}, records=${records.length}');

      await db.transaction((txn) async {
        await txn.delete('records');
        await txn.delete('contacts');
        await txn.delete('events');

        for (final e in events) {
          await txn.insert('events', Map<String, dynamic>.from(e as Map));
        }

        for (final c in contacts) {
          await txn.insert('contacts', Map<String, dynamic>.from(c as Map));
        }

        for (final r in records) {
          await txn.insert('records', Map<String, dynamic>.from(r as Map));
        }
      });

      AppLogger.backup('JSON恢复: 数据库写入完成, 刷新 Provider');
      ref.invalidate(eventListProvider);
      ref.invalidate(contactListProvider);
      ref.invalidate(recordListProvider);
      ref.invalidate(contactWithBalanceProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('数据恢复成功')));
      }
    } catch (e, stack) {
      AppLogger.error('JSON恢复失败', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('恢复失败: $e')));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}
