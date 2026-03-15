class Contact {
  final int? id;
  final String name;
  final String? memo;
  final String? pinyin;
  final int createdAt;

  const Contact({
    this.id,
    required this.name,
    this.memo,
    this.pinyin,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'memo': memo,
        'pinyin': pinyin,
        'created_at': createdAt,
      };

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as int?,
        name: map['name'] as String,
        memo: map['memo'] as String?,
        pinyin: map['pinyin'] as String?,
        createdAt: map['created_at'] as int,
      );

  Contact copyWith({
    int? id,
    String? name,
    String? memo,
    String? pinyin,
    int? createdAt,
  }) =>
      Contact(
        id: id ?? this.id,
        name: name ?? this.name,
        memo: memo ?? this.memo,
        pinyin: pinyin ?? this.pinyin,
        createdAt: createdAt ?? this.createdAt,
      );
}
