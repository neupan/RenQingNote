class Event {
  final int? id;
  final String name;
  final String? icon;
  final int sortOrder;
  final bool isPreset;
  final int createdAt;

  const Event({
    this.id,
    required this.name,
    this.icon,
    this.sortOrder = 0,
    this.isPreset = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
        'is_preset': isPreset ? 1 : 0,
        'created_at': createdAt,
      };

  factory Event.fromMap(Map<String, dynamic> map) => Event(
        id: map['id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
        isPreset: (map['is_preset'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as int,
      );

  Event copyWith({
    int? id,
    String? name,
    String? icon,
    int? sortOrder,
    bool? isPreset,
    int? createdAt,
  }) =>
      Event(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
        isPreset: isPreset ?? this.isPreset,
        createdAt: createdAt ?? this.createdAt,
      );
}
