import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/record.dart';

class RecordRepository {
  final DatabaseHelper _dbHelper;

  RecordRepository(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(GiftRecord record) async {
    final db = await _db;
    return db.insert('records', record.toMap());
  }

  Future<int> update(GiftRecord record) async {
    final db = await _db;
    return db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取全部流水 (JOIN 联系人 + 事件)
  Future<List<GiftRecord>> getAll() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT r.*, c.name as contact_name, e.name as event_name, e.icon as event_icon
      FROM records r
      INNER JOIN contacts c ON r.contact_id = c.id
      INNER JOIN events e ON r.event_id = e.id
      ORDER BY r.record_date DESC
    ''');
    return rows.map(GiftRecord.fromMap).toList();
  }

  /// 获取某联系人的全部流水
  Future<List<GiftRecord>> getByContactId(int contactId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT r.*, c.name as contact_name, e.name as event_name, e.icon as event_icon
      FROM records r
      INNER JOIN contacts c ON r.contact_id = c.id
      INNER JOIN events e ON r.event_id = e.id
      WHERE r.contact_id = ?
      ORDER BY r.record_date DESC
    ''', [contactId]);
    return rows.map(GiftRecord.fromMap).toList();
  }

  /// 年度汇总: 返回 {0: totalOut, 1: totalIn}
  Future<Map<int, double>> getYearSummary(int year) async {
    final start =
        DateTime(year).millisecondsSinceEpoch;
    final end =
        DateTime(year + 1).millisecondsSinceEpoch;
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM records
      WHERE record_date >= ? AND record_date < ?
      GROUP BY type
    ''', [start, end]);

    final result = <int, double>{0: 0.0, 1: 0.0};
    for (final row in rows) {
      result[row['type'] as int] = (row['total'] as num).toDouble();
    }
    return result;
  }

  /// 获取全部数据用于导出 (JOIN)
  Future<List<Map<String, dynamic>>> getAllForExport() async {
    final db = await _db;
    return db.rawQuery('''
      SELECT r.*, c.name as contact_name, e.name as event_name
      FROM records r
      INNER JOIN contacts c ON r.contact_id = c.id
      INNER JOIN events e ON r.event_id = e.id
      ORDER BY r.record_date DESC
    ''');
  }
}
