// lib/core/database/sync_queue.dart
import 'dart:convert';
import 'local_db.dart';

class SyncQueue {
  static Future<void> enqueue(String action, Map<String, dynamic> payload) async {
    final db = await LocalDb.instance;
    await db.insert('sync_queue', {
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> pending() async {
    final db = await LocalDb.instance;
    return db.query('sync_queue', orderBy: 'id ASC');
  }

  static Future<void> remove(int id) async {
    final db = await LocalDb.instance;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> incrementAttempts(int id) async {
    final db = await LocalDb.instance;
    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?', [id]);
  }
}
