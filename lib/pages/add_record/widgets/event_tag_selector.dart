import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/icon_map.dart';
import '../../../core/utils/logger.dart';
import '../../../models/event.dart';
import '../../../providers/event_providers.dart';

class EventTagSelector extends ConsumerStatefulWidget {
  final Event? initialEvent;
  final ValueChanged<Event> onSelected;

  const EventTagSelector({
    super.key,
    this.initialEvent,
    required this.onSelected,
  });

  @override
  ConsumerState<EventTagSelector> createState() => _EventTagSelectorState();
}

class _EventTagSelectorState extends ConsumerState<EventTagSelector> {
  final _searchController = TextEditingController();
  int? _selectedId;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialEvent?.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(Event event) {
    _searchController.text = event.name;
    setState(() {
      _selectedId = event.id;
      _filter = '';
    });
    widget.onSelected(event);
    FocusScope.of(context).unfocus();
  }

  Future<void> _createAndSelect(String name) async {
    AppLogger.ui('EventTagSelector.create: name="$name"');
    final now = DateTime.now().millisecondsSinceEpoch;
    final event = Event(name: name, icon: 'more_horiz', createdAt: now);
    final id = await ref.read(eventListProvider.notifier).add(event);
    final created = event.copyWith(id: id);
    AppLogger.ui('EventTagSelector.create: 完成, id=$id');
    _select(created);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已成功创建新事件：$name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: '事件',
            hintText: '搜索或创建新事件',
            prefixIcon: Icon(Icons.event),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final trimmed = v.trim();
            AppLogger.ui('EventTagSelector.filter: "$trimmed"');
            setState(() => _filter = trimmed);
          },
        ),
        const SizedBox(height: 8),
        eventsAsync.when(
          data: (events) {
            final filtered = _filter.isEmpty
                ? events
                : events
                    .where((e) =>
                        e.name.contains(_filter))
                    .toList();
            final exactMatch = events.any((e) => e.name == _filter);

            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...filtered.map((e) => ChoiceChip(
                      avatar: Icon(getEventIcon(e.icon), size: 18),
                      label: Text(e.name),
                      selected: _selectedId == e.id,
                      onSelected: (_) => _select(e),
                    )),
                if (_filter.isNotEmpty && !exactMatch)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18, color: Colors.blue),
                    label: Text('创建: $_filter',
                        style: const TextStyle(color: Colors.blue)),
                    onPressed: () => _createAndSelect(_filter),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('加载失败: $e'),
        ),
      ],
    );
  }
}
