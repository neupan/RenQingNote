import 'package:flutter/material.dart';

const kIconMap = <String, IconData>{
  'favorite': Icons.favorite,
  'child_friendly': Icons.child_friendly,
  'cake': Icons.cake,
  'home': Icons.home,
  'school': Icons.school,
  'local_florist': Icons.local_florist,
  'redeem': Icons.redeem,
  'store': Icons.store,
  'more_horiz': Icons.more_horiz,
  'card_giftcard': Icons.card_giftcard,
  'celebration': Icons.celebration,
  'emoji_events': Icons.emoji_events,
  'work': Icons.work,
  'restaurant': Icons.restaurant,
  'flight': Icons.flight,
  'medical_services': Icons.medical_services,
};

IconData getEventIcon(String? iconName) =>
    kIconMap[iconName] ?? Icons.more_horiz;
