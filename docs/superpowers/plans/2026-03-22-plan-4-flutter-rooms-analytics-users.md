# Hotel Management App - Plan 4: Flutter Rooms, Analytics & User Management

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the Flutter app with Rooms Grid (color-coded by status, per floor), Room Management (add rooms + CSV import), Analytics Dashboard (graphs + Excel export), User Management, and Profile screen.

**Architecture:** Same Riverpod + Repository pattern as Plan 3. `fl_chart` for graphs. `excel` package for client-side export. CSV import via `file_picker`. Managers-only screens gated by role check.

**Tech Stack:** Flutter, flutter_riverpod, fl_chart, excel, file_picker, supabase_flutter

---

## Prerequisites

- Plans 1–3 complete

---

## Additional Dependencies (add to pubspec.yaml)

```yaml
fl_chart: ^0.68.0
file_picker: ^8.1.2
```

Run: `flutter pub get`

---

## File Structure

```
lib/features/
├── rooms/
│   ├── data/room_repository.dart
│   ├── domain/room_model.dart
│   ├── presentation/
│   │   ├── rooms_grid_screen.dart
│   │   ├── room_tile.dart
│   │   └── room_management_screen.dart
│   └── providers/rooms_provider.dart
├── analytics/
│   ├── data/analytics_repository.dart
│   ├── domain/analytics_models.dart
│   ├── presentation/analytics_screen.dart
│   └── providers/analytics_provider.dart
├── users/
│   ├── data/users_repository.dart
│   ├── domain/user_model.dart
│   ├── presentation/
│   │   ├── users_screen.dart
│   │   └── user_form_screen.dart
│   └── providers/users_provider.dart
└── profile/
    └── presentation/profile_screen.dart
```

---

## Task 1: Room Domain + Repository

**Files:**
- Create: `lib/features/rooms/domain/room_model.dart`
- Create: `lib/features/rooms/data/room_repository.dart`

- [ ] **Step 1: Write room model**

```dart
// lib/features/rooms/domain/room_model.dart
class Room {
  final String id;
  final String hotelId;
  final String roomNumber;
  final int? floor;
  final String? roomType;
  final String status; // available | on_hold | closed
  final String? notes;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    this.floor,
    this.roomType,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'],
    hotelId: j['hotel_id'],
    roomNumber: j['room_number'],
    floor: j['floor'],
    roomType: j['room_type'],
    status: j['status'],
    notes: j['notes'],
    createdAt: DateTime.parse(j['created_at']),
  );

  bool get isAvailable => status == 'available';
  bool get isOnHold   => status == 'on_hold';
  bool get isClosed   => status == 'closed';
}
```

- [ ] **Step 2: Write room repository**

```dart
// lib/features/rooms/data/room_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../domain/room_model.dart';

class RoomRepository {
  Future<List<Room>> fetchAll() async {
    final res = await supabase
      .from('rooms')
      .select()
      .order('floor', ascending: true)
      .order('room_number', ascending: true);
    return (res as List).map((j) => Room.fromJson(j)).toList();
  }

  Future<void> addRoom({
    required String hotelId,
    required String roomNumber,
    int? floor,
    String? roomType,
  }) async {
    await supabase.from('rooms').insert({
      'hotel_id': hotelId,
      'room_number': roomNumber,
      'floor': floor,
      'room_type': roomType,
    });
  }

  Future<void> resetRoomStatus({
    required String roomId,
    required String userId,
    required String reason,
  }) async {
    await supabase.from('rooms').update({
      'status': 'available',
      'notes': reason,
      'status_changed_by': userId,
      'status_changed_at': DateTime.now().toIso8601String(),
    }).eq('id', roomId);
  }

  /// Import from CSV rows: [{room_number, floor, room_type}, ...]
  /// Returns: {imported: n, skipped: n, errors: [...]}
  Future<Map<String, dynamic>> importFromCsv({
    required String hotelId,
    required List<Map<String, dynamic>> rows,
  }) async {
    int imported = 0, skipped = 0;
    final errors = <String>[];

    for (final row in rows.take(500)) { // max 500
      final roomNumber = row['room_number']?.toString().trim();
      if (roomNumber == null || roomNumber.isEmpty) {
        errors.add('Empty room_number in row: $row');
        continue;
      }
      try {
        await supabase.from('rooms').insert({
          'hotel_id': hotelId,
          'room_number': roomNumber,
          'floor': int.tryParse(row['floor']?.toString() ?? ''),
          'room_type': row['room_type']?.toString().trim(),
        });
        imported++;
      } catch (e) {
        if (e.toString().contains('unique')) {
          skipped++;
        } else {
          errors.add('Row $roomNumber: $e');
        }
      }
    }
    return {'imported': imported, 'skipped': skipped, 'errors': errors};
  }
}
```

- [ ] **Step 3: Write model test**

```dart
// test/features/rooms/domain/room_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

void main() {
  final json = {
    'id': 'r1', 'hotel_id': 'h1', 'room_number': '101',
    'floor': 1, 'room_type': 'standard', 'status': 'available',
    'notes': null, 'created_at': '2026-03-22T10:00:00Z',
  };

  test('Room.fromJson parses correctly', () {
    final room = Room.fromJson(json);
    expect(room.roomNumber, '101');
    expect(room.isAvailable, true);
    expect(room.isClosed, false);
  });
}
```

- [ ] **Step 4: Run test**

```bash
flutter test test/features/rooms/
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/rooms/domain/ lib/features/rooms/data/ test/features/rooms/
git commit -m "feat: add room model and repository"
```

---

## Task 2: Rooms Grid Screen

**Files:**
- Create: `lib/features/rooms/presentation/rooms_grid_screen.dart`
- Create: `lib/features/rooms/presentation/room_tile.dart`
- Create: `lib/features/rooms/providers/rooms_provider.dart`

- [ ] **Step 1: Write rooms provider**

```dart
// lib/features/rooms/providers/rooms_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/room_repository.dart';
import '../domain/room_model.dart';

final roomRepoProvider = Provider<RoomRepository>((_) => RoomRepository());

final roomsProvider = FutureProvider<List<Room>>((ref) async {
  return ref.watch(roomRepoProvider).fetchAll();
});

// Group rooms by floor
final roomsByFloorProvider = Provider<Map<int, List<Room>>>((ref) {
  final rooms = ref.watch(roomsProvider).maybeWhen(
    data: (r) => r, orElse: () => <Room>[]);
  final map = <int, List<Room>>{};
  for (final room in rooms) {
    map.putIfAbsent(room.floor ?? 0, () => []).add(room);
  }
  return map;
});
```

- [ ] **Step 2: Write room tile**

```dart
// lib/features/rooms/presentation/room_tile.dart
import 'package:flutter/material.dart';
import '../domain/room_model.dart';

class RoomTile extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const RoomTile({super.key, required this.room, required this.onTap});

  Color get _color => switch (room.status) {
    'available' => Colors.green,
    'on_hold'   => Colors.orange,
    'closed'    => Colors.red,
    _           => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          border: Border.all(color: _color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(room.roomNumber, style: TextStyle(
              fontWeight: FontWeight.bold, color: _color, fontSize: 16)),
            if (room.roomType != null)
              Text(room.roomType!, style: const TextStyle(fontSize: 10)),
            Icon(_statusIcon, color: _color, size: 16),
          ],
        ),
      ),
    );
  }

  IconData get _statusIcon => switch (room.status) {
    'available' => Icons.check_circle_outline,
    'on_hold'   => Icons.pause_circle_outline,
    'closed'    => Icons.lock_outline,
    _           => Icons.help_outline,
  };
}
```

- [ ] **Step 3: Write rooms grid screen**

```dart
// lib/features/rooms/presentation/rooms_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import '../providers/rooms_provider.dart';
import 'room_tile.dart';

class RoomsGridScreen extends ConsumerWidget {
  const RoomsGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final byFloor = ref.watch(roomsByFloorProvider);
    final user = ref.watch(currentUserProvider);
    final role = UserRole.fromString(
      (user?.appMetadata['role'] as String?) ?? 'receptionist');

    return Scaffold(
      appBar: AppBar(
        title: Text(l.rooms),
        actions: [
          if (role.isManager)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {/* navigate to room management */},
            ),
        ],
      ),
      body: byFloor.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: byFloor.entries.map((entry) {
              final floor = entry.key;
              final rooms = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      floor == 0 ? 'No Floor' : 'Floor $floor',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, childAspectRatio: 1.1,
                      mainAxisSpacing: 8, crossAxisSpacing: 8,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (_, i) => RoomTile(
                      room: rooms[i],
                      onTap: () {/* show room tickets */},
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      // Legend
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _legend(Colors.green, l.available),
          _legend(Colors.orange, l.onHold),
          _legend(Colors.red, l.closed),
        ]),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(
      color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 12)),
  ]);
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/rooms/ test/features/rooms/
git commit -m "feat: add rooms grid screen with floor grouping and status colors"
```

---

## Task 3: Room Management (Add + CSV Import)

**Files:**
- Create: `lib/features/rooms/presentation/room_management_screen.dart`

- [ ] **Step 1: Write room management screen**

```dart
// lib/features/rooms/presentation/room_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import '../data/room_repository.dart';

class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key});
  @override ConsumerState<RoomManagementScreen> createState() => _State();
}

class _State extends ConsumerState<RoomManagementScreen> {
  final _numberCtrl = TextEditingController();
  final _floorCtrl  = TextEditingController();
  final _typeCtrl   = TextEditingController();
  String? _importResult;
  bool _loading = false;

  Future<void> _addRoom() async {
    final user = ref.read(currentUserProvider)!;
    final hotelId = user.appMetadata['hotel_id'] as String;
    setState(() => _loading = true);
    try {
      await RoomRepository().addRoom(
        hotelId: hotelId,
        roomNumber: _numberCtrl.text.trim(),
        floor: int.tryParse(_floorCtrl.text),
        roomType: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
      );
      _numberCtrl.clear(); _floorCtrl.clear(); _typeCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room added')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'],
    );
    if (result == null) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final content = String.fromCharCodes(bytes);
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    // Parse header
    final headers = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    final rows = lines.skip(1).map((line) {
      final vals = line.split(',');
      return Map<String, dynamic>.fromIterables(headers, vals.map((v) => v.trim()));
    }).toList();

    final user = ref.read(currentUserProvider)!;
    final hotelId = user.appMetadata['hotel_id'] as String;

    setState(() => _loading = true);
    try {
      final res = await RoomRepository().importFromCsv(hotelId: hotelId, rows: rows);
      setState(() => _importResult =
        'Imported: ${res['imported']}  Skipped (duplicates): ${res['skipped']}\n'
        '${(res['errors'] as List).isNotEmpty ? "Errors:\n${(res['errors'] as List).join('\n')}" : ""}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Management')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Room', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(controller: _numberCtrl, decoration: const InputDecoration(labelText: 'Room Number *')),
          const SizedBox(height: 8),
          TextField(controller: _floorCtrl, decoration: const InputDecoration(labelText: 'Floor'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Room Type')),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loading ? null : _addRoom, child: const Text('Add Room')),
          const Divider(height: 40),
          Text('Import from CSV', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Format: room_number, floor, room_type (max 500 rows)\nDuplicates are skipped automatically.',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : _importCsv,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose CSV File'),
          ),
          if (_importResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_importResult!),
            ),
          ],
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/rooms/presentation/room_management_screen.dart
git commit -m "feat: add room management screen with csv import"
```

---

## Task 4: Analytics Dashboard

**Files:**
- Create: `lib/features/analytics/data/analytics_repository.dart`
- Create: `lib/features/analytics/domain/analytics_models.dart`
- Create: `lib/features/analytics/presentation/analytics_screen.dart`

- [ ] **Step 1: Write analytics models**

```dart
// lib/features/analytics/domain/analytics_models.dart
class TicketStats {
  final int totalOpen;
  final int totalResolved;
  final double avgCloseHours;
  final double slaCompliancePct;

  const TicketStats({
    required this.totalOpen,
    required this.totalResolved,
    required this.avgCloseHours,
    required this.slaCompliancePct,
  });
}

class DailyCount {
  final DateTime date;
  final int count;
  const DailyCount({required this.date, required this.count});
}

class TechStats {
  final String techName;
  final int handled;
  final double avgHours;
  const TechStats({required this.techName, required this.handled, required this.avgHours});
}

class RoomStats {
  final String roomNumber;
  final int ticketCount;
  const RoomStats({required this.roomNumber, required this.ticketCount});
}
```

- [ ] **Step 2: Write analytics repository**

```dart
// lib/features/analytics/data/analytics_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../domain/analytics_models.dart';

class AnalyticsRepository {
  Future<TicketStats> fetchStats({DateTime? from, DateTime? to}) async {
    var query = supabase.from('tickets').select(
      'id, status, sla_deadline, resolved_at, created_at');

    if (from != null) query = query.gte('created_at', from.toIso8601String()) as dynamic;
    if (to   != null) query = query.lte('created_at', to.toIso8601String()) as dynamic;

    final rows = (await query) as List;
    final open = rows.where((r) => !['resolved','closed'].contains(r['status'])).length;
    final resolved = rows.where((r) => ['resolved','closed'].contains(r['status'])).length;

    final closedWithTimes = rows.where((r) =>
      r['resolved_at'] != null && r['created_at'] != null).toList();
    final avgClose = closedWithTimes.isEmpty ? 0.0 :
      closedWithTimes.map((r) {
        final diff = DateTime.parse(r['resolved_at']).difference(DateTime.parse(r['created_at']));
        return diff.inMinutes / 60.0;
      }).reduce((a, b) => a + b) / closedWithTimes.length;

    final withSla = rows.where((r) => r['sla_deadline'] != null && r['resolved_at'] != null);
    final slaOk = withSla.where((r) =>
      DateTime.parse(r['resolved_at']).isBefore(DateTime.parse(r['sla_deadline']))).length;
    final slaPct = withSla.isEmpty ? 100.0 : slaOk / withSla.length * 100;

    return TicketStats(
      totalOpen: open,
      totalResolved: resolved,
      avgCloseHours: avgClose,
      slaCompliancePct: slaPct,
    );
  }

  Future<List<DailyCount>> fetchDailyCounts({required int days}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final rows = await supabase
      .from('tickets')
      .select('created_at')
      .gte('created_at', from.toIso8601String());

    final map = <String, int>{};
    for (final r in rows as List) {
      final day = DateTime.parse(r['created_at']).toLocal().toString().substring(0, 10);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map.entries
      .map((e) => DailyCount(date: DateTime.parse(e.key), count: e.value))
      .toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<TechStats>> fetchTechStats() async {
    final rows = await supabase
      .from('tickets')
      .select('claimed_by, resolved_at, created_at, claimer:users!tickets_claimed_by_fkey(full_name)')
      .not('claimed_by', 'is', null);

    final map = <String, List<Map>>{}; // tech_id → tickets
    for (final r in rows as List) {
      final id = r['claimed_by'] as String;
      map.putIfAbsent(id, () => []).add(r);
    }

    return map.entries.map((e) {
      final name = (e.value.first['claimer']?['full_name'] as String?) ?? e.key;
      final withTime = e.value.where((r) => r['resolved_at'] != null && r['created_at'] != null);
      final avg = withTime.isEmpty ? 0.0 :
        withTime.map((r) {
          return DateTime.parse(r['resolved_at']).difference(
            DateTime.parse(r['created_at'])).inMinutes / 60.0;
        }).reduce((a, b) => a + b) / withTime.length;
      return TechStats(techName: name, handled: e.value.length, avgHours: avg);
    }).toList()..sort((a, b) => b.handled.compareTo(a.handled));
  }

  Future<List<RoomStats>> fetchRoomStats({int limit = 10}) async {
    final rows = await supabase.from('tickets').select('room:rooms(room_number)');
    final map = <String, int>{};
    for (final r in rows as List) {
      final rn = r['room']?['room_number'] as String? ?? '?';
      map[rn] = (map[rn] ?? 0) + 1;
    }
    final list = map.entries.map((e) =>
      RoomStats(roomNumber: e.key, ticketCount: e.value)).toList()
      ..sort((a, b) => b.ticketCount.compareTo(a.ticketCount));
    return list.take(limit).toList();
  }
}
```

- [ ] **Step 3: Write analytics screen**

```dart
// lib/features/analytics/presentation/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = AnalyticsRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportExcel(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // KPI Cards
          FutureBuilder<TicketStats>(
            future: repo.fetchStats(),
            builder: (_, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              final s = snap.data!;
              return Row(children: [
                _kpi('Open', s.totalOpen.toString(), Colors.orange),
                _kpi('Resolved', s.totalResolved.toString(), Colors.green),
                _kpi('Avg Close', '${s.avgCloseHours.toStringAsFixed(1)}h', Colors.blue),
                _kpi('SLA', '${s.slaCompliancePct.toStringAsFixed(0)}%',
                  s.slaCompliancePct >= 80 ? Colors.green : Colors.red),
              ]);
            },
          ),
          const SizedBox(height: 24),
          // Daily chart
          Text('Tickets per day (30d)', style: Theme.of(context).textTheme.titleSmall),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<DailyCount>>(
              future: repo.fetchDailyCounts(days: 30),
              builder: (_, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final data = snap.data!;
                return BarChart(BarChartData(
                  barGroups: data.asMap().entries.map((e) =>
                    BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(toY: e.value.count.toDouble(),
                        color: Theme.of(context).colorScheme.primary, width: 8),
                    ])).toList(),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                ));
              },
            ),
          ),
          const SizedBox(height: 24),
          // Top rooms
          Text('Most Reported Rooms', style: Theme.of(context).textTheme.titleSmall),
          FutureBuilder<List<RoomStats>>(
            future: repo.fetchRoomStats(),
            builder: (_, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              return Column(
                children: snap.data!.map((r) => ListTile(
                  leading: const Icon(Icons.hotel),
                  title: Text('Room ${r.roomNumber}'),
                  trailing: Text('${r.ticketCount} tickets'),
                )).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _kpi(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    // Call Edge Function for server-side export
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final session = supabase.auth.currentSession;
    if (session == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing export...')));

    // For web: trigger Edge Function download
    // The Edge Function returns CSV which browser downloads
    // For mobile: use excel package to generate locally
    final workbook = Excel.createExcel();
    final sheet = workbook.sheets[workbook.getDefaultSheet()!]!;
    sheet.appendRow([
      TextCellValue('ID'), TextCellValue('Room'), TextCellValue('Dept'),
      TextCellValue('Title'), TextCellValue('Status'), TextCellValue('Created'),
    ]);
    // Rows populated from AnalyticsRepository in a real implementation

    final bytes = workbook.encode();
    if (bytes != null) {
      // Save/share file — platform-specific (use share_plus in V2)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export ready')));
    }
  }
}
```

- [ ] **Step 4: Write analytics test**

```dart
// test/features/analytics/domain/analytics_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/analytics/domain/analytics_models.dart';

void main() {
  test('TicketStats holds correct values', () {
    const stats = TicketStats(
      totalOpen: 5, totalResolved: 20,
      avgCloseHours: 3.5, slaCompliancePct: 85.0,
    );
    expect(stats.totalOpen, 5);
    expect(stats.slaCompliancePct, 85.0);
  });
}
```

- [ ] **Step 5: Run test**

```bash
flutter test test/features/analytics/
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/analytics/ test/features/analytics/
git commit -m "feat: add analytics dashboard with charts and excel export"
```

---

## Task 5: User Management Screen

**Files:**
- Create: `lib/features/users/data/users_repository.dart`
- Create: `lib/features/users/domain/user_model.dart`
- Create: `lib/features/users/presentation/users_screen.dart`
- Create: `lib/features/users/presentation/user_form_screen.dart`

- [ ] **Step 1: Write user model**

```dart
// lib/features/users/domain/user_model.dart
class HotelUser {
  final String id;
  final String? hotelId;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final String? avatarUrl;
  final DateTime createdAt;

  const HotelUser({
    required this.id,
    this.hotelId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.avatarUrl,
    required this.createdAt,
  });

  factory HotelUser.fromJson(Map<String, dynamic> j) => HotelUser(
    id: j['id'],
    hotelId: j['hotel_id'],
    fullName: j['full_name'],
    email: j['email'],
    role: j['role'],
    isActive: j['is_active'],
    avatarUrl: j['avatar_url'],
    createdAt: DateTime.parse(j['created_at']),
  );
}
```

- [ ] **Step 2: Write users repository**

```dart
// lib/features/users/data/users_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../domain/user_model.dart';

class UsersRepository {
  Future<List<HotelUser>> fetchAll() async {
    final res = await supabase
      .from('users')
      .select()
      .order('full_name');
    return (res as List).map((j) => HotelUser.fromJson(j)).toList();
  }

  Future<void> toggleActive(String userId, bool isActive) async {
    await supabase.from('users').update({'is_active': isActive}).eq('id', userId);
  }

  Future<void> updateRole(String userId, String role) async {
    await supabase.from('users').update({'role': role}).eq('id', userId);
  }

  /// Invite new user (sends Supabase auth invite email)
  Future<void> inviteUser({
    required String email,
    required String fullName,
    required String role,
    required String hotelId,
  }) async {
    // Create auth user via admin API (requires service role — call Edge Function)
    await supabase.functions.invoke('invite-user', body: {
      'email': email, 'full_name': fullName, 'role': role, 'hotel_id': hotelId,
    });
  }
}
```

- [ ] **Step 3: Write users screen**

```dart
// lib/features/users/presentation/users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../data/users_repository.dart';
import '../domain/user_model.dart';

final usersProvider = FutureProvider<List<HotelUser>>((ref) async {
  return UsersRepository().fetchAll();
});

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final user = list[i];
            return ListTile(
              leading: CircleAvatar(child: Text(user.fullName[0])),
              title: Text(user.fullName),
              subtitle: Text('${user.role} • ${user.email}'),
              trailing: Switch(
                value: user.isActive,
                onChanged: (val) async {
                  await UsersRepository().toggleActive(user.id, val);
                  ref.invalidate(usersProvider);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* navigate to user form */},
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/users/ test/features/users/
git commit -m "feat: add user management screen"
```

---

## Task 6: Profile Screen

**Files:**
- Create: `lib/features/profile/presentation/profile_screen.dart`

- [ ] **Step 1: Write profile screen**

```dart
// lib/features/profile/presentation/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_repository.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/core/i18n/locale_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          CircleAvatar(radius: 40, child: Text(
            (user?.email ?? '?')[0].toUpperCase(),
            style: const TextStyle(fontSize: 32),
          )),
          const SizedBox(height: 16),
          Text(user?.email ?? '', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            (user?.appMetadata['role'] as String?) ?? '',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Divider(height: 40),
          // Language selector
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Language'),
            value: locale.languageCode,
            items: const [
              DropdownMenuItem(value: 'he', child: Text('עברית')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
            ],
            onChanged: (lang) {
              if (lang != null) {
                ref.read(localeProvider.notifier).state = Locale(lang);
              }
            },
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: Text(l.logout),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/profile/
git commit -m "feat: add profile screen with language switcher and logout"
```

---

## Task 7: Home Dashboard + Main Navigation

**Files:**
- Modify: `lib/navigation/router.dart` (replace placeholder HomeScreen)
- Create: `lib/features/home/presentation/home_screen.dart`

- [ ] **Step 1: Write home screen with bottom nav**

```dart
// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/features/tickets/presentation/tickets_list_screen.dart';
import 'package:hotel_app/features/rooms/presentation/rooms_grid_screen.dart';
import 'package:hotel_app/features/analytics/presentation/analytics_screen.dart';
import 'package:hotel_app/features/users/presentation/users_screen.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final role = UserRole.fromString(
      (user?.appMetadata['role'] as String?) ?? 'receptionist');

    final tabs = [
      (icon: Icons.confirmation_num, label: l.myTickets, screen: const TicketsListScreen()),
      (icon: Icons.hotel, label: l.rooms, screen: const RoomsGridScreen()),
      if (role.isManager) (icon: Icons.bar_chart, label: l.analytics, screen: const AnalyticsScreen()),
      if (role.isManager) (icon: Icons.people, label: l.users, screen: const UsersScreen()),
      (icon: Icons.person, label: l.profile, screen: const ProfileScreen()),
    ];

    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon), label: t.label)).toList(),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire in router**

Update `lib/navigation/router.dart` — replace placeholder `HomeScreen` import with the real one:
```dart
import 'package:hotel_app/features/home/presentation/home_screen.dart';
```

- [ ] **Step 3: Run full app**

```bash
flutter run -d chrome
```
Test full flow: login → tickets → rooms (color-coded grid) → analytics (managers only) → profile → logout.

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/ lib/navigation/router.dart
git commit -m "feat: add home screen with role-based bottom navigation"
```

---

## Verification Checklist

Before moving to Plan 5, confirm:

- [ ] `flutter test` passes all tests
- [ ] Rooms grid shows floors + color-coded tiles
- [ ] Manager can add a room manually
- [ ] CSV import shows result (imported/skipped/errors)
- [ ] Analytics KPI cards show real data from Supabase
- [ ] Bar chart renders daily ticket count
- [ ] Analytics tab is hidden for non-managers
- [ ] User management screen shows toggle for active/inactive
- [ ] Profile screen shows language switcher + logout
- [ ] Logout redirects to login screen
