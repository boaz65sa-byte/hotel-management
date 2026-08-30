import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hotel_app/core/database/sync_queue.dart';
import 'package:hotel_app/core/database/local_db.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    LocalDb.resetForTest();
    final db = await LocalDb.instance;
    await db.delete('sync_queue');
  });

  test('enqueue adds item, pending returns it, remove clears it', () async {
    await SyncQueue.enqueue('create_ticket', {'title': 'Test'});
    final items = await SyncQueue.pending();
    expect(items.length, 1);
    expect(items.first['action'], 'create_ticket');

    await SyncQueue.remove(items.first['id'] as int);
    expect((await SyncQueue.pending()).length, 0);
  });

  test('incrementAttempts increases count', () async {
    await SyncQueue.enqueue('update_ticket', {'id': '123'});
    final items = await SyncQueue.pending();
    final id = items.first['id'] as int;
    await SyncQueue.incrementAttempts(id);
    final updated = await SyncQueue.pending();
    expect(updated.first['attempts'], 1);
  });
}
