import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/logger.dart';
import '../../models/contact.dart';
import '../../models/event.dart';
import '../../models/record.dart';
import '../../providers/record_providers.dart';
import '../../providers/contact_providers.dart';
import 'widgets/contact_picker.dart';
import 'widgets/event_tag_selector.dart';

class AddRecordPage extends ConsumerStatefulWidget {
  final GiftRecord? editRecord;
  final Contact? editContact;
  final Event? editEvent;

  const AddRecordPage({
    super.key,
    this.editRecord,
    this.editContact,
    this.editEvent,
  });

  @override
  ConsumerState<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends ConsumerState<AddRecordPage> {
  int _type = 0; // 0=随礼, 1=收礼
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Contact? _selectedContact;
  Event? _selectedEvent;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.editRecord != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final r = widget.editRecord!;
      _type = r.type;
      _amountController.text = r.amount.toStringAsFixed(
          r.amount.truncateToDouble() == r.amount ? 0 : 2);
      _noteController.text = r.note ?? '';
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(r.recordDate);
      _selectedContact = widget.editContact;
      _selectedEvent = widget.editEvent;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    AppLogger.ui('AddRecord._save: 开始, type=$_type, amount="${_amountController.text}", contactId=${_selectedContact?.id}, eventId=${_selectedEvent?.id}, date=${DateFormat('yyyy-MM-dd').format(_selectedDate)}');

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      AppLogger.ui('AddRecord._save: 校验失败 - 金额无效');
      _showError('请输入有效金额');
      return;
    }
    if (_selectedContact == null || _selectedContact!.id == null) {
      AppLogger.ui('AddRecord._save: 校验失败 - 未选择联系人');
      _showError('请选择对象');
      return;
    }
    if (_selectedEvent == null || _selectedEvent!.id == null) {
      AppLogger.ui('AddRecord._save: 校验失败 - 未选择事件');
      _showError('请选择事件');
      return;
    }

    final record = GiftRecord(
      id: widget.editRecord?.id,
      contactId: _selectedContact!.id!,
      eventId: _selectedEvent!.id!,
      type: _type,
      amount: amount,
      recordDate: _selectedDate.millisecondsSinceEpoch,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    final notifier = ref.read(recordListProvider.notifier);
    if (_isEditing) {
      await notifier.updateRecord(record);
      AppLogger.ui('AddRecord._save: 编辑完成, id=${record.id}');
    } else {
      await notifier.add(record);
      AppLogger.ui('AddRecord._save: 新增完成');
    }
    ref.invalidate(contactListProvider);

    if (mounted) Navigator.of(context).pop(true);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑记录' : '记一笔'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 收/支切换
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: const Text('随礼 (支出)'),
                  icon: const Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 1,
                  label: const Text('收礼 (收入)'),
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _type == 0
                        ? Colors.red.withAlpha(30)
                        : Colors.green.withAlpha(30);
                  }
                  return null;
                }),
              ),
            ),
            const SizedBox(height: 20),

            // 金额
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),

            // 联系人
            ContactPicker(
              initialContact: _selectedContact,
              onSelected: (c) => _selectedContact = c,
            ),
            const SizedBox(height: 16),

            // 事件
            EventTagSelector(
              initialEvent: _selectedEvent,
              onSelected: (e) => _selectedEvent = e,
            ),
            const SizedBox(height: 16),

            // 日期
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // 备注
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注 (选填)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
