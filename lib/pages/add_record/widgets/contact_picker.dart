import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lpinyin/lpinyin.dart';

import '../../../models/contact.dart';
import '../../../providers/database_provider.dart';

class ContactPicker extends ConsumerStatefulWidget {
  final Contact? initialContact;
  final ValueChanged<Contact> onSelected;

  const ContactPicker({
    super.key,
    this.initialContact,
    required this.onSelected,
  });

  @override
  ConsumerState<ContactPicker> createState() => _ContactPickerState();
}

class _ContactPickerState extends ConsumerState<ContactPicker> {
  final _controller = TextEditingController();
  List<Contact> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialContact != null) {
      _controller.text = widget.initialContact!.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String value) async {
    final keyword = value.trim();
    if (keyword.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final repo = ref.read(contactRepositoryProvider);
    final contacts = await repo.search(keyword);
    if (mounted) {
      setState(() {
        _results = contacts;
        _searching = false;
      });
    }
  }

  void _selectContact(Contact contact) {
    _controller.text = contact.name;
    widget.onSelected(contact);
    setState(() => _results = []);
    FocusScope.of(context).unfocus();
  }

  Future<void> _createAndSelect(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pinyin = PinyinHelper.getPinyin(name, separator: '');
    final contact = Contact(name: name, pinyin: pinyin, createdAt: now);
    final repo = ref.read(contactRepositoryProvider);
    final id = await repo.insert(contact);
    final created = contact.copyWith(id: id);
    _selectContact(created);
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _controller.text.trim();
    final exactMatch = _results.any((c) => c.name == keyword);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: '对象',
            hintText: '搜索或输入新联系人',
            prefixIcon: Icon(Icons.person_search),
            border: OutlineInputBorder(),
          ),
          onChanged: _onChanged,
        ),
        if (_searching) const LinearProgressIndicator(),
        if (_results.isNotEmpty || (keyword.isNotEmpty && !exactMatch))
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                ..._results.map((c) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.person),
                      title: Text(c.name),
                      subtitle: c.memo != null && c.memo!.isNotEmpty
                          ? Text(c.memo!)
                          : null,
                      onTap: () => _selectContact(c),
                    )),
                if (keyword.isNotEmpty && !exactMatch)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_add, color: Colors.blue),
                    title: Text('创建新联系人: $keyword',
                        style: const TextStyle(color: Colors.blue)),
                    onTap: () => _createAndSelect(keyword),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
