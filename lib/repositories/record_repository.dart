import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/utils/logger.dart';
import '../models/record.dart';

class RecordRepository {
  final DatabaseHelper _dbHelper;

  RecordRepository(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(GiftRecord record) async {
    final db = await _db;
    final id = await db.insert('records', record.toMap());
    AppLogger.db('RecordRepository.insert: id=$id, contactId=${record.contactId}, eventId=${record.eventId}, type=${record.type}, amount=${record.amount}');
    return id;
  }

  Future<int> update(GiftRecord record) async {
    final db = await _db;
    final rows = await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    AppLogger.db('RecordRepository.update: id=${record.id}, affected=$rows');
    return rows;
  }

  Future<int> delete(int id) async {
    final db = await _db;
    final rows = await db.delete('records', where: 'id = ?', whereArgs: [id]);
    AppLogger.db('RecordRepository.delete: id=$id, affected=$rows');
    return rows;
  }

  Future<List<GiftRecord>> getAll() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT r.*, c.name as contact_name, e.name as event_name, e.icon as event_icon
      FROM records r
      INNER JOIN contacts c ON r.contact_id = c.id
      INNER JOIN events e ON r.event_id = e.id
      ORDER BY r.record_date DESC
    ''');
    AppLogger.db('RecordRepository.getAll: 共 ${rows.length} 条记录');
    return rows.map(GiftRecord.fromMap).toList();
  }

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
    AppLogger.db('RecordRepository.getByContactId: contactId=$contactId, 共 ${rows.length} 条');
    return rows.map(GiftRecord.fromMap).toList();
  }

  Future<Map<int, double>> getYearSummary(int year) async {
    final start = DateTime(year).millisecondsSinceEpoch;
    final end = DateTime(year + 1).millisecondsSinceEpoch;
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
    AppLogger.db('RecordRepository.getYearSummary: year=$year, 收礼=${result[1]}, 随礼=${result[0]}');
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllForExport() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT r.*, c.name as contact_name, e.name as event_name
      FROM records r
      INNER JOIN contacts c ON r.contact_id = c.id
      INNER JOIN events e ON r.event_id = e.id
      ORDER BY r.record_date DESC
    ''');
    AppLogger.db('RecordRepository.getAllForExport: 共 ${rows.length} 条');
    return rows;
  }
}
