import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contact.dart';
import 'database_provider.dart';

final contactListProvider =
    AsyncNotifierProvider<ContactListNotifier, List<Contact>>(
  ContactListNotifier.new,
);

class ContactListNotifier extends AsyncNotifier<List<Contact>> {
  @override
  Future<List<Contact>> build() =>
      ref.read(contactRepositoryProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(
      await ref.read(contactRepositoryProvider).getAll(),
    );
  }

  Future<int> add(Contact contact) async {
    final id = await ref.read(contactRepositoryProvider).insert(contact);
    await refresh();
    return id;
  }

  Future<void> updateContact(Contact contact) async {
    await ref.read(contactRepositoryProvider).update(contact);
    await refresh();
  }

  Future<void> delete(int id) async {
    await ref.read(contactRepositoryProvider).delete(id);
    await refresh();
  }
}

/// 联系人 + 盈亏数据
final contactWithBalanceProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(contactListProvider);
  return ref.read(contactRepositoryProvider).getAllWithBalance();
});
