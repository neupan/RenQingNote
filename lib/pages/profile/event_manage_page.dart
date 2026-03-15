import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/icon_map.dart';
import '../../models/event.dart';
import '../../providers/event_providers.dart';

class EventManagePage extends ConsumerWidget {
  const EventManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('事件管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('暂无事件类型'));
          }
          return ReorderableListView.builder(
            itemCount: events.length,
            onReorder: (oldIndex, newIndex) =>
                _reorder(ref, events, oldIndex, newIndex),
            itemBuilder: (_, i) {
              final e = events[i];
              return ListTile(
                key: ValueKey(e.id),
                leading: CircleAvatar(child: Icon(getEventIcon(e.icon))),
                title: Text(e.name),
                subtitle: e.isPreset ? const Text('系统预设') : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditDialog(context, ref, e),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteEvent(context, ref, e),
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  void _reorder(WidgetRef ref, List<Event> events, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final list = List<Event>.from(events);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    ref.read(eventListProvider.notifier).reorder(list);
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    String selectedIcon = 'more_horiz';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新增事件'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '事件名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _IconPicker(
                selected: selectedIcon,
                onChanged: (v) => setDialogState(() => selectedIcon = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('添加')),
          ],
        ),
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await ref.read(eventListProvider.notifier).add(Event(
            name: nameController.text.trim(),
            icon: selectedIcon,
            createdAt: now,
          ));
    }
    nameController.dispose();
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Event event) async {
    final nameController = TextEditingController(text: event.name);
    String selectedIcon = event.icon ?? 'more_horiz';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('编辑事件'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '事件名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _IconPicker(
                selected: selectedIcon,
                onChanged: (v) => setDialogState(() => selectedIcon = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('保存')),
          ],
        ),
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      await ref.read(eventListProvider.notifier).updateEvent(
            event.copyWith(
                name: nameController.text.trim(), icon: selectedIcon),
          );
    }
    nameController.dispose();
  }

  Future<void> _deleteEvent(
      BuildContext context, WidgetRef ref, Event event) async {
    final success =
        await ref.read(eventListProvider.notifier).delete(event.id!);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该事件下有关联记录，无法删除')),
      );
    }
  }
}

class _IconPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _IconPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kIconMap.entries.map((entry) {
        final isSelected = entry.key == selected;
        return GestureDetector(
          onTap: () => onChanged(entry.key),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            child: Icon(entry.value, size: 24),
          ),
        );
      }).toList(),
    );
  }
}
