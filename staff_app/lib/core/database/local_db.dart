// lib/core/database/local_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'hotel_app.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        action      TEXT NOT NULL,
        payload     TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        attempts    INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_tickets (
        id            TEXT PRIMARY KEY,
        hotel_id      TEXT NOT NULL,
        data          TEXT NOT NULL,
        synced_at     TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_rooms (
        id        TEXT PRIMARY KEY,
        hotel_id  TEXT NOT NULL,
        data      TEXT NOT NULL,
        synced_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE hotel_config (
        hotel_id        TEXT PRIMARY KEY,
        theme_colors    TEXT,
        logo_url        TEXT,
        default_language TEXT,
        cached_at       TEXT NOT NULL
      )
    ''');
  }

  /// Reset for testing
  static void resetForTest() => _db = null;
}
