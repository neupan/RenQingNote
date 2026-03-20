import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/logger.dart';
import '../models/contact.dart';
import 'database_provider.dart';

final contactListProvider =
    AsyncNotifierProvider<ContactListNotifier, List<Contact>>(
  ContactListNotifier.new,
);

class ContactListNotifier extends AsyncNotifier<List<Contact>> {
  @override
  Future<List<Contact>> build() async {
    AppLogger.provider('ContactListNotifier.build: 初始化加载');
    final contacts = await ref.read(contactRepositoryProvider).getAll();
    AppLogger.provider('ContactListNotifier.build: 加载完成, 共 ${contacts.length} 个联系人');
    return contacts;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(
      await ref.read(contactRepositoryProvider).getAll(),
    );
  }

  Future<int> add(Contact contact) async {
    AppLogger.provider('ContactListNotifier.add: name=${contact.name}');
    final id = await ref.read(contactRepositoryProvider).insert(contact);
    await refresh();
    AppLogger.provider('ContactListNotifier.add: 完成, id=$id');
    return id;
  }

  Future<void> updateContact(Contact contact) async {
    AppLogger.provider('ContactListNotifier.updateContact: id=${contact.id}, name=${contact.name}');
    await ref.read(contactRepositoryProvider).update(contact);
    await refresh();
  }

  Future<void> delete(int id) async {
    AppLogger.provider('ContactListNotifier.delete: id=$id');
    await ref.read(contactRepositoryProvider).delete(id);
    await refresh();
    AppLogger.provider('ContactListNotifier.delete: 完成');
  }
}

final contactWithBalanceProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(contactListProvider);
  AppLogger.provider('contactWithBalanceProvider: 加载联系人盈亏数据');
  return ref.read(contactRepositoryProvider).getAllWithBalance();
});
