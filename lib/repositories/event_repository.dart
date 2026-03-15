import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/event.dart';

class EventRepository {
  final DatabaseHelper _dbHelper;

  EventRepository(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(Event event) async {
    final db = await _db;
    return db.insert('events', event.toMap());
  }

  Future<int> update(Event event) async {
    final db = await _db;
    return db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Event>> getAll() async {
    final db = await _db;
    final rows = await db.query('events', orderBy: 'sort_order ASC');
    return rows.map(Event.fromMap).toList();
  }

  Future<List<Event>> search(String keyword) async {
    final db = await _db;
    final rows = await db.query(
      'events',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'sort_order ASC',
    );
    return rows.map(Event.fromMap).toList();
  }

  /// 检查事件是否被流水记录引用
  Future<int> getRecordCount(int eventId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM records WHERE event_id = ?',
      [eventId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateSortOrders(List<Event> events) async {
    final db = await _db;
    final batch = db.batch();
    for (var i = 0; i < events.length; i++) {
      batch.update(
        'events',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [events[i].id],
      );
    }
    await batch.commit(noResult: true);
  }
}
