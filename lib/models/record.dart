class GiftRecord {
  final int? id;
  final int contactId;
  final int eventId;
  final int type; // 0=随礼/支出, 1=收礼/收入
  final double amount;
  final int recordDate;
  final String? note;

  // JOIN 查询附带字段
  final String? contactName;
  final String? eventName;
  final String? eventIcon;

  const GiftRecord({
    this.id,
    required this.contactId,
    required this.eventId,
    required this.type,
    required this.amount,
    required this.recordDate,
    this.note,
    this.contactName,
    this.eventName,
    this.eventIcon,
  });

  bool get isIncome => type == 1;
  bool get isExpense => type == 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'contact_id': contactId,
        'event_id': eventId,
        'type': type,
        'amount': amount,
        'record_date': recordDate,
        'note': note,
      };

  factory GiftRecord.fromMap(Map<String, dynamic> map) => GiftRecord(
        id: map['id'] as int?,
        contactId: map['contact_id'] as int,
        eventId: map['event_id'] as int,
        type: map['type'] as int,
        amount: (map['amount'] as num).toDouble(),
        recordDate: map['record_date'] as int,
        note: map['note'] as String?,
        contactName: map['contact_name'] as String?,
        eventName: map['event_name'] as String?,
        eventIcon: map['event_icon'] as String?,
      );

  GiftRecord copyWith({
    int? id,
    int? contactId,
    int? eventId,
    int? type,
    double? amount,
    int? recordDate,
    String? note,
  }) =>
      GiftRecord(
        id: id ?? this.id,
        contactId: contactId ?? this.contactId,
        eventId: eventId ?? this.eventId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        recordDate: recordDate ?? this.recordDate,
        note: note ?? this.note,
      );
}
