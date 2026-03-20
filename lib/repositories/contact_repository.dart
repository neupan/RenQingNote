import 'package:lpinyin/lpinyin.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/utils/logger.dart';
import '../models/contact.dart';

class ContactRepository {
  final DatabaseHelper _dbHelper;

  ContactRepository(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(Contact contact) async {
    final db = await _db;
    final pinyin = PinyinHelper.getPinyin(contact.name, separator: '');
    final id = await db.insert('contacts', contact.copyWith(pinyin: pinyin).toMap());
    AppLogger.db('ContactRepository.insert: id=$id, name=${contact.name}, pinyin=$pinyin');
    return id;
  }

  Future<int> update(Contact contact) async {
    final db = await _db;
    final pinyin = PinyinHelper.getPinyin(contact.name, separator: '');
    final rows = await db.update(
      'contacts',
      contact.copyWith(pinyin: pinyin).toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
    AppLogger.db('ContactRepository.update: id=${contact.id}, name=${contact.name}, affected=$rows');
    return rows;
  }

  Future<int> delete(int id) async {
    final db = await _db;
    final rows = await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
    AppLogger.db('ContactRepository.delete: id=$id, affected=$rows (级联删除records)');
    return rows;
  }

  Future<List<Contact>> getAll() async {
    final db = await _db;
    final rows = await db.query('contacts', orderBy: 'pinyin ASC');
    AppLogger.db('ContactRepository.getAll: 共 ${rows.length} 个联系人');
    return rows.map(Contact.fromMap).toList();
  }

  Future<Contact?> getById(int id) async {
    final db = await _db;
    final rows =
        await db.query('contacts', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Contact.fromMap(rows.first);
  }

  Future<List<Contact>> search(String keyword) async {
    final db = await _db;
    final rows = await db.query(
      'contacts',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'pinyin ASC',
    );
    AppLogger.db('ContactRepository.search: keyword="$keyword", 匹配 ${rows.length} 个');
    return rows.map(Contact.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getAllWithBalance() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT c.*,
        IFNULL(SUM(CASE WHEN r.type = 1 THEN r.amount ELSE 0 END), 0) as total_in,
        IFNULL(SUM(CASE WHEN r.type = 0 THEN r.amount ELSE 0 END), 0) as total_out
      FROM contacts c
      LEFT JOIN records r ON c.id = r.contact_id
      GROUP BY c.id
      ORDER BY c.pinyin ASC
    ''');
    AppLogger.db('ContactRepository.getAllWithBalance: 共 ${rows.length} 个联系人(含盈亏)');
    return rows;
  }
}
