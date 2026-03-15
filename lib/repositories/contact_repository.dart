import 'package:lpinyin/lpinyin.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/contact.dart';

class ContactRepository {
  final DatabaseHelper _dbHelper;

  ContactRepository(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(Contact contact) async {
    final db = await _db;
    final pinyin = PinyinHelper.getPinyin(contact.name, separator: '');
    return db.insert('contacts', contact.copyWith(pinyin: pinyin).toMap());
  }

  Future<int> update(Contact contact) async {
    final db = await _db;
    final pinyin = PinyinHelper.getPinyin(contact.name, separator: '');
    return db.update(
      'contacts',
      contact.copyWith(pinyin: pinyin).toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Contact>> getAll() async {
    final db = await _db;
    final rows = await db.query('contacts', orderBy: 'pinyin ASC');
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
    return rows.map(Contact.fromMap).toList();
  }

  /// 返回联系人列表，每人附带盈亏数据
  Future<List<Map<String, dynamic>>> getAllWithBalance() async {
    final db = await _db;
    return db.rawQuery('''
      SELECT c.*,
        IFNULL(SUM(CASE WHEN r.type = 1 THEN r.amount ELSE 0 END), 0) as total_in,
        IFNULL(SUM(CASE WHEN r.type = 0 THEN r.amount ELSE 0 END), 0) as total_out
      FROM contacts c
      LEFT JOIN records r ON c.id = r.contact_id
      GROUP BY c.id
      ORDER BY c.pinyin ASC
    ''');
  }
}
