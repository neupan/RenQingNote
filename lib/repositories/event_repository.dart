import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/utils/logger.dart';
import '../models/event.dart';

class EventRepository {
  final DatabaseHelper _dbHelper;

  EventRepository(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(Event event) async {
    final db = await _db;
    final id = await db.insert('events', event.toMap());
    AppLogger.db('EventRepository.insert: id=$id, name=${event.name}, icon=${event.icon}');
    return id;
  }

  Future<int> update(Event event) async {
    final db = await _db;
    final rows = await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    AppLogger.db('EventRepository.update: id=${event.id}, name=${event.name}, affected=$rows');
    return rows;
  }

  Future<int> delete(int id) async {
    final db = await _db;
    final rows = await db.delete('events', where: 'id = ?', whereArgs: [id]);
    AppLogger.db('EventRepository.delete: id=$id, affected=$rows');
    return rows;
  }

  Future<List<Event>> getAll() async {
    final db = await _db;
    final rows = await db.query('events', orderBy: 'sort_order ASC');
    AppLogger.db('EventRepository.getAll: 共 ${rows.length} 个事件类型');
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
    AppLogger.db('EventRepository.search: keyword="$keyword", 匹配 ${rows.length} 个');
    return rows.map(Event.fromMap).toList();
  }

  Future<int> getRecordCount(int eventId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM records WHERE event_id = ?',
      [eventId],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    AppLogger.db('EventRepository.getRecordCount: eventId=$eventId, 引用数=$count');
    return count;
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
    AppLogger.db('EventRepository.updateSortOrders: 更新 ${events.length} 个事件排序');
  }
}
