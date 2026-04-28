# Housekeeping Full Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable managers to assign dirty rooms to housekeeping staff, and staff to complete cleaning via checklist with real-time status tracking.

**Architecture:** Two role-based screens routed from HomeScreen: HousekeepingManagerScreen (assign rooms, summary bar, real-time stream) and HousekeepingStaffScreen (see assigned rooms, launch checklist, mark clean). Data flows through a dedicated HousekeepingRepository + Riverpod StreamProviders. Room model extended with assignedTo/assignedToName fields.

**Tech Stack:** Flutter + Riverpod (StreamProvider), Supabase Realtime stream, existing ChecklistScreen, Navy dark theme (#0a1628 bg, #0f1f3d surface, #c9a84c gold).

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/features/rooms/domain/room_model.dart` | Add `assignedTo`, `assignedToName` fields |
| Modify | `lib/features/tickets/domain/ticket_status.dart` | Add `housekeeping` to UserRole enum; update `homeScreen` getter |
| Modify | `lib/features/users/presentation/new_user_screen.dart` | Add 'housekeeping' to role dropdown |
| Modify | `lib/features/tickets/data/ticket_repository.dart` | Add 'housekeeping' to fetchDeptStaff |
| Create | `lib/features/housekeeping/data/housekeeping_repository.dart` | Data access: stream rooms, fetch staff, CRUD ops |
| Create | `lib/features/housekeeping/providers/housekeeping_providers.dart` | StreamProviders + FutureProvider |
| Create | `lib/features/housekeeping/presentation/housekeeping_manager_screen.dart` | Manager UI: summary bar, filter, room list, assignment sheet |
| Create | `lib/features/housekeeping/presentation/housekeeping_staff_screen.dart` | Staff UI: assigned rooms, start/continue cleaning |
| Modify | `lib/features/home/presentation/home_screen.dart` | Route 'housekeeping_manager'/'housekeeping_staff' to new screens |
| Create | `test/features/housekeeping/housekeeping_test.dart` | Widget tests for both screens |

---

## Task 1: SQL Migration + Room Model

**Files:**
- SQL: run in Supabase SQL editor
- Modify: `lib/features/rooms/domain/room_model.dart`
- Test: `test/features/housekeeping/housekeeping_test.dart`

- [ ] **Step 1: Run SQL migration in Supabase**

In the Supabase SQL editor, run:

```sql
ALTER TABLE rooms
  ADD COLUMN IF NOT EXISTS assigned_to uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS assigned_to_name text;
```

- [ ] **Step 2: Write the failing test**

Create `test/features/housekeeping/housekeeping_test.dart`:

```dart
// test/features/housekeeping/housekeeping_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

void main() {
  group('Room model', () {
    test('fromJson parses assignedTo and assignedToName', () {
      final json = {
        'id': 'r1',
        'hotel_id': 'h1',
        'room_number': '101',
        'floor': 1,
        'room_type': 'standard',
        'status': 'available',
        'notes': null,
        'housekeeping_status': 'dirty',
        'assigned_to': 'user-uuid-123',
        'assigned_to_name': 'Dana Cohen',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final room = Room.fromJson(json);
      expect(room.assignedTo, 'user-uuid-123');
      expect(room.assignedToName, 'Dana Cohen');
    });

    test('fromJson defaults assignedTo to null when absent', () {
      final json = {
        'id': 'r2',
        'hotel_id': 'h1',
        'room_number': '102',
        'status': 'available',
        'housekeeping_status': 'clean',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final room = Room.fromJson(json);
      expect(room.assignedTo, isNull);
      expect(room.assignedToName, isNull);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
cd "/Users/boazsaada/manegmant resapceon"
flutter test test/features/housekeeping/housekeeping_test.dart
```

Expected: FAIL — `Room` has no `assignedTo` field.

- [ ] **Step 4: Update Room model**

Replace `lib/features/rooms/domain/room_model.dart` entirely:

```dart
class Room {
  final String id;
  final String hotelId;
  final String roomNumber;
  final int? floor;
  final String? roomType;
  final String status; // available | on_hold | closed
  final String? notes;
  final String housekeepingStatus; // clean | dirty | cleaning
  final String? assignedTo;
  final String? assignedToName;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    this.floor,
    this.roomType,
    required this.status,
    this.notes,
    this.housekeepingStatus = 'clean',
    this.assignedTo,
    this.assignedToName,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'] as String,
    hotelId: j['hotel_id'] as String,
    roomNumber: j['room_number'] as String,
    floor: j['floor'] as int?,
    roomType: j['room_type'] as String?,
    status: j['status'] as String,
    notes: j['notes'] as String?,
    housekeepingStatus: j['housekeeping_status'] as String? ?? 'clean',
    assignedTo: j['assigned_to'] as String?,
    assignedToName: j['assigned_to_name'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  bool get isAvailable => status == 'available';
  bool get isOnHold   => status == 'on_hold';
  bool get isClosed   => status == 'closed';
}

/// Alias for backwards-compatible references to RoomModel.
typedef RoomModel = Room;
```

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/features/housekeeping/housekeeping_test.dart
```

Expected: PASS (2 tests).

- [ ] **Step 6: Run all tests**

```bash
flutter test
```

Expected: all tests pass (no regressions).

- [ ] **Step 7: Commit**

```bash
git add lib/features/rooms/domain/room_model.dart test/features/housekeeping/housekeeping_test.dart
git commit -m "feat: extend Room model with assignedTo/assignedToName (housekeeping Phase 9)"
```

---

## Task 2: UserRole + Staff Role

**Files:**
- Modify: `lib/features/tickets/domain/ticket_status.dart`
- Modify: `lib/features/users/presentation/new_user_screen.dart`
- Modify: `lib/features/tickets/data/ticket_repository.dart`

- [ ] **Step 1: Update UserRole enum**

In `lib/features/tickets/domain/ticket_status.dart`, replace the entire file:

```dart
// lib/features/tickets/domain/ticket_status.dart
enum TicketStatus { open, inProgress, pendingApproval, resolved, closed }

enum UserRole {
  superAdmin, ceo, hotelAdmin, receptionManager, maintenanceManager,
  housekeepingManager, housekeeping, securityManager, deputyReception,
  receptionist, securityGuard, maintenanceTech, repairman;

  static UserRole fromString(String s) {
    final camel = _toCamel(s);
    final match = UserRole.values.where((r) => r.name == camel).firstOrNull;
    assert(match != null, 'Unknown role string: $s');
    return match ?? UserRole.receptionist;
  }

  static String _toCamel(String s) {
    final parts = s.split('_');
    return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  static const _managerRoles = [
    superAdmin, ceo, hotelAdmin, receptionManager, maintenanceManager,
    housekeepingManager, securityManager,
  ];

  bool get canClaimAndUpdate => this != UserRole.receptionist;
  bool get canApproveRoomClose => _managerRoles.contains(this);
  bool get isManager => _managerRoles.contains(this);
  bool get isRequiredApprover =>
    this == UserRole.receptionManager || this == UserRole.maintenanceManager;

  String get homeScreen {
    if (this == UserRole.housekeepingManager) return 'housekeeping_manager';
    if (this == UserRole.housekeeping) return 'housekeeping_staff';
    if (this == UserRole.ceo || this == UserRole.superAdmin) return 'manager';
    if (this == UserRole.maintenanceTech ||
        this == UserRole.repairman ||
        this == UserRole.maintenanceManager) return 'maintenance';
    return 'reception';
  }
}
```

Note: `housekeepingManager` homeScreen changed from `'housekeeping'` to `'housekeeping_manager'`.

- [ ] **Step 2: Add 'housekeeping' to new_user_screen.dart**

In `lib/features/users/presentation/new_user_screen.dart`, find the `_roles` list (line 9) and add `('housekeeping', 'Housekeeping Staff')`:

```dart
const _roles = [
  ('ceo', 'CEO'),
  ('reception_manager', 'Reception Manager'),
  ('maintenance_manager', 'Maintenance Manager'),
  ('housekeeping_manager', 'Housekeeping Manager'),
  ('housekeeping', 'Housekeeping Staff'),
  ('security_manager', 'Security Manager'),
  ('deputy_reception', 'Deputy Reception'),
  ('receptionist', 'Receptionist'),
  ('security_guard', 'Security Guard'),
  ('maintenance_tech', 'Maintenance Tech'),
  ('repairman', 'Repairman'),
];
```

- [ ] **Step 3: Add 'housekeeping' to fetchDeptStaff**

In `lib/features/tickets/data/ticket_repository.dart`, find `fetchDeptStaff` (around line 260). Update the `deptRoles` map:

```dart
final deptRoles = <String, List<String>>{
  'maintenance': ['maintenance_manager', 'maintenance_tech', 'repairman'],
  'reception': ['reception_manager', 'deputy_reception', 'receptionist'],
  'security': ['security_manager', 'security_guard'],
  'housekeeping': ['housekeeping_manager', 'housekeeping'],
};
```

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/domain/ticket_status.dart lib/features/users/presentation/new_user_screen.dart lib/features/tickets/data/ticket_repository.dart
git commit -m "feat: add housekeeping staff role to UserRole enum and user invite"
```

---

## Task 3: Housekeeping Repository

**Files:**
- Create: `lib/features/housekeeping/data/housekeeping_repository.dart`

- [ ] **Step 1: Create the repository**

Create `lib/features/housekeeping/data/housekeeping_repository.dart`:

```dart
// lib/features/housekeeping/data/housekeeping_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

class StaffMember {
  final String id;
  final String name;
  final int assignedCount;
  const StaffMember({required this.id, required this.name, required this.assignedCount});
}

class HousekeepingRepository {
  /// Streams all dirty/cleaning rooms for the hotel (manager view).
  Stream<List<Room>> streamAllRooms(String hotelId) {
    return supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => Room.fromJson(j))
            .where((r) =>
                r.housekeepingStatus == 'dirty' ||
                r.housekeepingStatus == 'cleaning')
            .toList()
          ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber)));
  }

  /// Streams rooms assigned to a specific staff member.
  Stream<List<Room>> streamMyRooms(String hotelId, String staffId) {
    return supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => Room.fromJson(j))
            .where((r) =>
                r.assignedTo == staffId &&
                (r.housekeepingStatus == 'dirty' ||
                    r.housekeepingStatus == 'cleaning'))
            .toList()
          ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber)));
  }

  /// Fetches all active housekeeping staff with their current room assignment count.
  Future<List<StaffMember>> fetchStaffList(String hotelId) async {
    final rooms = await supabase
        .from('rooms')
        .select('assigned_to')
        .eq('hotel_id', hotelId)
        .inFilter('housekeeping_status', ['dirty', 'cleaning']);

    final countMap = <String, int>{};
    for (final r in rooms as List) {
      final id = r['assigned_to'] as String?;
      if (id != null) countMap[id] = (countMap[id] ?? 0) + 1;
    }

    final users = await supabase
        .from('users')
        .select('id, full_name')
        .inFilter('role', ['housekeeping', 'housekeeping_manager'])
        .eq('is_active', true);

    return (users as List).map((u) {
      final id = u['id'] as String;
      return StaffMember(
        id: id,
        name: u['full_name'] as String,
        assignedCount: countMap[id] ?? 0,
      );
    }).toList();
  }

  /// Assigns a room to a staff member.
  Future<void> assignRoom(String roomId, String staffId, String staffName) async {
    await supabase.from('rooms').update({
      'assigned_to': staffId,
      'assigned_to_name': staffName,
    }).eq('id', roomId);
    // TODO(Module 4): send push notification to assigned_to
  }

  /// Clears assignment from a room.
  Future<void> unassignRoom(String roomId) async {
    await supabase.from('rooms').update({
      'assigned_to': null,
      'assigned_to_name': null,
    }).eq('id', roomId);
  }

  /// Updates room status to 'cleaning'.
  Future<void> startCleaning(String roomId) async {
    await supabase.from('rooms').update({
      'housekeeping_status': 'cleaning',
    }).eq('id', roomId);
  }

  /// Updates room status to 'clean' and clears assignment.
  Future<void> markClean(String roomId) async {
    await supabase.from('rooms').update({
      'housekeeping_status': 'clean',
      'assigned_to': null,
      'assigned_to_name': null,
    }).eq('id', roomId);
  }

  /// Creates a housekeeping checklist instance for a room.
  /// Returns the new instance ID.
  Future<String> createHousekeepingInstance({
    required String roomId,
    required String hotelId,
    required String staffId,
  }) async {
    final templates = await supabase
        .from('checklist_templates')
        .select('id')
        .eq('type', 'housekeeping')
        .limit(1);

    if ((templates as List).isEmpty) {
      throw Exception('לא נמצאה תבנית צ׳קליסט לניקיון. צור תבנית מסוג housekeeping בלוח הניהול.');
    }

    final templateId = templates.first['id'] as String;

    final instance = await supabase
        .from('checklist_instances')
        .insert({
          'template_id': templateId,
          'hotel_id': hotelId,
          'room_id': roomId,
          'assigned_to': staffId,
        })
        .select()
        .single();

    final instanceId = instance['id'] as String;

    final items = await supabase
        .from('checklist_items')
        .select()
        .eq('template_id', templateId)
        .order('order_index');

    await supabase.from('checklist_instance_items').insert(
      (items as List)
          .map((item) => {'instance_id': instanceId, 'item_id': item['id']})
          .toList(),
    );

    return instanceId;
  }

  /// Returns true if the checklist instance has been completed.
  Future<bool> isInstanceCompleted(String instanceId) async {
    final result = await supabase
        .from('checklist_instances')
        .select('completed_at')
        .eq('id', instanceId)
        .single();
    return result['completed_at'] != null;
  }
}
```

- [ ] **Step 2: Run all tests (compile check)**

```bash
flutter test
```

Expected: all tests pass (new file compiles correctly).

- [ ] **Step 3: Commit**

```bash
git add lib/features/housekeeping/data/housekeeping_repository.dart
git commit -m "feat: add HousekeepingRepository with stream, assign, and checklist support"
```

---

## Task 4: Housekeeping Providers

**Files:**
- Create: `lib/features/housekeeping/providers/housekeeping_providers.dart`

- [ ] **Step 1: Create providers**

Create `lib/features/housekeeping/providers/housekeeping_providers.dart`:

```dart
// lib/features/housekeeping/providers/housekeeping_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/housekeeping/data/housekeeping_repository.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

final housekeepingRepositoryProvider =
    Provider<HousekeepingRepository>((_) => HousekeepingRepository());

/// All dirty/cleaning rooms for the hotel (manager view).
final allHousekeepingRoomsProvider = StreamProvider<List<Room>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return const Stream.empty();
  return ref
      .read(housekeepingRepositoryProvider)
      .streamAllRooms(hotelId);
});

/// Rooms assigned to the current user (staff view).
final myAssignedRoomsProvider = StreamProvider<List<Room>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  final staffId = user?.id;
  if (hotelId == null || staffId == null) return const Stream.empty();
  return ref
      .read(housekeepingRepositoryProvider)
      .streamMyRooms(hotelId, staffId);
});

/// All active housekeeping staff members with room counts.
final housekeepingStaffProvider =
    FutureProvider<List<StaffMember>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];
  return ref
      .read(housekeepingRepositoryProvider)
      .fetchStaffList(hotelId);
});
```

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/housekeeping/providers/housekeeping_providers.dart
git commit -m "feat: add housekeeping Riverpod providers (stream rooms, staff list)"
```

---

## Task 5: Manager Screen

**Files:**
- Create: `lib/features/housekeeping/presentation/housekeeping_manager_screen.dart`

- [ ] **Step 1: Create the manager screen**

Create `lib/features/housekeeping/presentation/housekeeping_manager_screen.dart`:

```dart
// lib/features/housekeeping/presentation/housekeeping_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/housekeeping/data/housekeeping_repository.dart';
import 'package:hotel_app/features/housekeeping/providers/housekeeping_providers.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

class HousekeepingManagerScreen extends ConsumerStatefulWidget {
  const HousekeepingManagerScreen({super.key});
  @override
  ConsumerState<HousekeepingManagerScreen> createState() =>
      _HousekeepingManagerScreenState();
}

class _HousekeepingManagerScreenState
    extends ConsumerState<HousekeepingManagerScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (icon: Icons.cleaning_services, label: 'ניהול חדרים', screen: const _ManagerRoomList()),
      (icon: Icons.person, label: 'פרופיל', screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _ManagerRoomList extends ConsumerStatefulWidget {
  const _ManagerRoomList();
  @override
  ConsumerState<_ManagerRoomList> createState() => _ManagerRoomListState();
}

class _ManagerRoomListState extends ConsumerState<_ManagerRoomList> {
  String _filter = 'הכול';

  static const _filters = ['הכול', 'מלוכלך', 'בניקיון', 'נקי'];
  static const _filterToStatus = {
    'מלוכלך': 'dirty',
    'בניקיון': 'cleaning',
    'נקי': 'clean',
  };

  List<Room> _applyFilter(List<Room> rooms) {
    if (_filter == 'הכול') return rooms;
    final status = _filterToStatus[_filter];
    return rooms.where((r) => r.housekeepingStatus == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(allHousekeepingRoomsProvider);

    return roomsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(child: Text('שגיאה: $e', style: const TextStyle(color: Colors.white))),
      ),
      data: (rooms) {
        final dirty = rooms.where((r) => r.housekeepingStatus == 'dirty').length;
        final cleaning = rooms.where((r) => r.housekeepingStatus == 'cleaning').length;
        final clean = rooms.where((r) => r.housekeepingStatus == 'clean').length;
        final filtered = _applyFilter(rooms);

        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.cleaning_services, color: Color(0xFFC9A84C)),
                      const SizedBox(width: 8),
                      const Text(
                        'ניהול ניקיון',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Summary bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _SummaryChip(label: '$dirty מלוכלכים', color: const Color(0xFFF87171)),
                      const SizedBox(width: 8),
                      _SummaryChip(label: '$cleaning בניקיון', color: const Color(0xFFFB923C)),
                      const SizedBox(width: 8),
                      _SummaryChip(label: '$clean נקיים', color: const Color(0xFF4ADE80)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _filters.map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: const Color(0xFFC9A84C),
                          backgroundColor: const Color(0xFF0F1F3D),
                          labelStyle: TextStyle(
                            color: selected ? Colors.black : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Room list
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'אין חדרים להצגה',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _RoomCard(
                            room: filtered[i],
                            onTap: () => _showAssignSheet(context, filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAssignSheet(BuildContext context, Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AssignSheet(room: room, ref: ref),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  const _RoomCard({required this.room, required this.onTap});

  static const _statusLabel = {
    'dirty': 'מלוכלך',
    'cleaning': 'בניקיון',
    'clean': 'נקי',
  };
  static const _statusColor = {
    'dirty': Color(0xFFF87171),
    'cleaning': Color(0xFFFB923C),
    'clean': Color(0xFF4ADE80),
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor[room.housekeepingStatus] ?? const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E3A5F)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hotel, color: Color(0xFF7C9DC4), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'חדר ${room.roomNumber}${room.floor != null ? " · קומה ${room.floor}" : ""}',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    room.assignedToName ?? 'לא מוקצה',
                    style: TextStyle(
                      color: room.assignedToName != null
                          ? const Color(0xFF7C9DC4)
                          : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(
                _statusLabel[room.housekeepingStatus] ?? room.housekeepingStatus,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF7C9DC4), size: 18),
          ],
        ),
      ),
    );
  }
}

class _AssignSheet extends ConsumerStatefulWidget {
  final Room room;
  final WidgetRef ref;
  const _AssignSheet({required this.room, required this.ref});

  @override
  ConsumerState<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends ConsumerState<_AssignSheet> {
  bool _loading = false;

  Future<void> _assign(StaffMember staff) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(housekeepingRepositoryProvider)
          .assignRoom(widget.room.id, staff.id, staff.name);
      ref.invalidate(housekeepingStaffProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unassign() async {
    setState(() => _loading = true);
    try {
      await ref.read(housekeepingRepositoryProvider).unassignRoom(widget.room.id);
      ref.invalidate(housekeepingStaffProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(housekeepingStaffProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'הקצה לחדר ${widget.room.roomNumber}',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('שגיאה: $e', style: const TextStyle(color: Colors.red)),
              data: (staff) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...staff.map((s) => ListTile(
                        leading: const Icon(Icons.person, color: Color(0xFF7C9DC4)),
                        title: Text(s.name,
                            style: const TextStyle(color: Color(0xFFE2E8F0))),
                        subtitle: Text('${s.assignedCount} חדרים',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 12)),
                        trailing: widget.room.assignedTo == s.id
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFFC9A84C))
                            : null,
                        onTap: () => _assign(s),
                      )),
                  if (widget.room.assignedTo != null) ...[
                    const Divider(color: Color(0xFF1E3A5F)),
                    ListTile(
                      leading: const Icon(Icons.remove_circle_outline,
                          color: Color(0xFFF87171)),
                      title: const Text('הסר הקצאה',
                          style: TextStyle(color: Color(0xFFF87171))),
                      onTap: _unassign,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/housekeeping/presentation/housekeeping_manager_screen.dart
git commit -m "feat: add HousekeepingManagerScreen with summary bar, filter, and assignment sheet"
```

---

## Task 6: Staff Screen

**Files:**
- Create: `lib/features/housekeeping/presentation/housekeeping_staff_screen.dart`

- [ ] **Step 1: Create the staff screen**

Create `lib/features/housekeeping/presentation/housekeeping_staff_screen.dart`:

```dart
// lib/features/housekeeping/presentation/housekeeping_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/housekeeping/providers/housekeeping_providers.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

class HousekeepingStaffScreen extends ConsumerStatefulWidget {
  const HousekeepingStaffScreen({super.key});
  @override
  ConsumerState<HousekeepingStaffScreen> createState() =>
      _HousekeepingStaffScreenState();
}

class _HousekeepingStaffScreenState
    extends ConsumerState<HousekeepingStaffScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (icon: Icons.cleaning_services, label: 'החדרים שלי', screen: const _StaffRoomList()),
      (icon: Icons.person, label: 'פרופיל', screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _StaffRoomList extends ConsumerWidget {
  const _StaffRoomList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String? ?? 'עובד';
    final roomsAsync = ref.watch(myAssignedRoomsProvider);

    return roomsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
            child: Text('שגיאה: $e',
                style: const TextStyle(color: Colors.white))),
      ),
      data: (rooms) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'שלום $userName',
                      style: const TextStyle(
                        color: Color(0xFFC9A84C),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'יש לך ${rooms.length} חדרים לניקוי',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: rooms.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Color(0xFF4ADE80), size: 48),
                            SizedBox(height: 12),
                            Text(
                              'אין חדרים להיום ✅',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: rooms.length,
                        itemBuilder: (_, i) =>
                            _StaffRoomCard(room: rooms[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffRoomCard extends ConsumerStatefulWidget {
  final Room room;
  const _StaffRoomCard({required this.room});

  @override
  ConsumerState<_StaffRoomCard> createState() => _StaffRoomCardState();
}

class _StaffRoomCardState extends ConsumerState<_StaffRoomCard> {
  bool _loading = false;

  Future<void> _startCleaning() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(housekeepingRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final hotelId = user?.appMetadata['hotel_id'] as String?;
      final staffId = user?.id;

      if (hotelId == null || staffId == null) throw Exception('לא מחובר');

      // Update status to cleaning
      await repo.startCleaning(widget.room.id);

      // Create checklist instance
      final instanceId = await repo.createHousekeepingInstance(
        roomId: widget.room.id,
        hotelId: hotelId,
        staffId: staffId,
      );

      if (mounted) {
        // Navigate to checklist screen and await return
        await context.push('/checklists/$instanceId');
      }

      if (mounted) {
        // Check if checklist was completed and mark room clean
        final completed = await repo.isInstanceCompleted(instanceId);
        if (completed) {
          await repo.markClean(widget.room.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueCleaning() async {
    // Find existing incomplete instance for this room
    setState(() => _loading = true);
    try {
      final instances = await supabase_ref(ref)
          .from('checklist_instances')
          .select('id')
          .eq('room_id', widget.room.id)
          .filter('completed_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(1);

      if ((instances as List).isEmpty) {
        // No active instance — create one
        await _startCleaning();
        return;
      }

      final instanceId = instances.first['id'] as String;
      if (mounted) {
        await context.push('/checklists/$instanceId');
      }

      if (mounted) {
        final repo = ref.read(housekeepingRepositoryProvider);
        final completed = await repo.isInstanceCompleted(instanceId);
        if (completed) {
          await repo.markClean(widget.room.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCleaning = widget.room.housekeepingStatus == 'cleaning';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: isCleaning
                  ? const Color(0xFFFB923C)
                  : const Color(0xFFF87171),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'חדר ${widget.room.roomNumber}${widget.room.floor != null ? " · קומה ${widget.room.floor}" : ""}',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCleaning ? 'בניקיון' : 'ממתין לניקוי',
                  style: TextStyle(
                    color: isCleaning
                        ? const Color(0xFFFB923C)
                        : const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton(
                  onPressed:
                      isCleaning ? _continueCleaning : _startCleaning,
                  style: FilledButton.styleFrom(
                    backgroundColor: isCleaning
                        ? const Color(0xFFFB923C)
                        : const Color(0xFFC9A84C),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: Text(isCleaning ? 'המשך' : 'התחל'),
                ),
        ],
      ),
    );
  }
}

// Helper to access supabase client via Riverpod context
import 'package:hotel_app/core/supabase/supabase_client.dart';
SupabaseClient supabase_ref(WidgetRef ref) => supabase;
```

**Note:** The `_continueCleaning` method queries Supabase directly to find the active instance. Replace the `supabase_ref` helper with the direct import pattern used in the rest of the codebase. Here is the corrected version of `_StaffRoomCard` that avoids the helper function:

Replace the entire `_StaffRoomCard` and `_StaffRoomCardState` with:

```dart
class _StaffRoomCard extends ConsumerStatefulWidget {
  final Room room;
  const _StaffRoomCard({required this.room});

  @override
  ConsumerState<_StaffRoomCard> createState() => _StaffRoomCardState();
}

class _StaffRoomCardState extends ConsumerState<_StaffRoomCard> {
  bool _loading = false;

  Future<void> _openChecklist(String instanceId) async {
    if (!mounted) return;
    await context.push('/checklists/$instanceId');
    if (!mounted) return;
    final completed = await ref
        .read(housekeepingRepositoryProvider)
        .isInstanceCompleted(instanceId);
    if (completed && mounted) {
      await ref
          .read(housekeepingRepositoryProvider)
          .markClean(widget.room.id);
    }
  }

  Future<void> _handleTap() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(housekeepingRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final hotelId = user?.appMetadata['hotel_id'] as String?;
      final staffId = user?.id;
      if (hotelId == null || staffId == null) throw Exception('לא מחובר');

      if (widget.room.housekeepingStatus == 'dirty') {
        await repo.startCleaning(widget.room.id);
        final instanceId = await repo.createHousekeepingInstance(
          roomId: widget.room.id,
          hotelId: hotelId,
          staffId: staffId,
        );
        await _openChecklist(instanceId);
      } else {
        // cleaning — find active instance
        final instances = await supabase
            .from('checklist_instances')
            .select('id')
            .eq('room_id', widget.room.id)
            .filter('completed_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(1);

        if ((instances as List).isNotEmpty) {
          await _openChecklist(instances.first['id'] as String);
        } else {
          // No active instance found — create a new one
          final instanceId = await repo.createHousekeepingInstance(
            roomId: widget.room.id,
            hotelId: hotelId,
            staffId: staffId,
          );
          await _openChecklist(instanceId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCleaning = widget.room.housekeepingStatus == 'cleaning';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: isCleaning ? const Color(0xFFFB923C) : const Color(0xFFF87171),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'חדר ${widget.room.roomNumber}${widget.room.floor != null ? " · קומה ${widget.room.floor}" : ""}',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCleaning ? 'בניקיון' : 'ממתין לניקוי',
                  style: TextStyle(
                    color: isCleaning ? const Color(0xFFFB923C) : const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton(
                  onPressed: _handleTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: isCleaning
                        ? const Color(0xFFFB923C)
                        : const Color(0xFFC9A84C),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle:
                        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: Text(isCleaning ? 'המשך' : 'התחל'),
                ),
        ],
      ),
    );
  }
}
```

The actual file to create is `lib/features/housekeeping/presentation/housekeeping_staff_screen.dart` with this full content:

```dart
// lib/features/housekeeping/presentation/housekeeping_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/housekeeping/providers/housekeeping_providers.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

class HousekeepingStaffScreen extends ConsumerStatefulWidget {
  const HousekeepingStaffScreen({super.key});
  @override
  ConsumerState<HousekeepingStaffScreen> createState() =>
      _HousekeepingStaffScreenState();
}

class _HousekeepingStaffScreenState
    extends ConsumerState<HousekeepingStaffScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (icon: Icons.cleaning_services, label: 'החדרים שלי', screen: const _StaffRoomList()),
      (icon: Icons.person, label: 'פרופיל', screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _StaffRoomList extends ConsumerWidget {
  const _StaffRoomList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String? ?? 'עובד';
    final roomsAsync = ref.watch(myAssignedRoomsProvider);

    return roomsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
            child: Text('שגיאה: $e',
                style: const TextStyle(color: Colors.white))),
      ),
      data: (rooms) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'שלום $userName',
                      style: const TextStyle(
                        color: Color(0xFFC9A84C),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'יש לך ${rooms.length} חדרים לניקוי',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: rooms.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Color(0xFF4ADE80), size: 48),
                            SizedBox(height: 12),
                            Text('אין חדרים להיום ✅',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: rooms.length,
                        itemBuilder: (_, i) =>
                            _StaffRoomCard(room: rooms[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffRoomCard extends ConsumerStatefulWidget {
  final Room room;
  const _StaffRoomCard({required this.room});

  @override
  ConsumerState<_StaffRoomCard> createState() => _StaffRoomCardState();
}

class _StaffRoomCardState extends ConsumerState<_StaffRoomCard> {
  bool _loading = false;

  Future<void> _openChecklist(String instanceId) async {
    if (!mounted) return;
    await context.push('/checklists/$instanceId');
    if (!mounted) return;
    final completed = await ref
        .read(housekeepingRepositoryProvider)
        .isInstanceCompleted(instanceId);
    if (completed && mounted) {
      await ref.read(housekeepingRepositoryProvider).markClean(widget.room.id);
    }
  }

  Future<void> _handleTap() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(housekeepingRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final hotelId = user?.appMetadata['hotel_id'] as String?;
      final staffId = user?.id;
      if (hotelId == null || staffId == null) throw Exception('לא מחובר');

      if (widget.room.housekeepingStatus == 'dirty') {
        await repo.startCleaning(widget.room.id);
        final instanceId = await repo.createHousekeepingInstance(
          roomId: widget.room.id,
          hotelId: hotelId,
          staffId: staffId,
        );
        await _openChecklist(instanceId);
      } else {
        // cleaning — find existing active instance
        final instances = await supabase
            .from('checklist_instances')
            .select('id')
            .eq('room_id', widget.room.id)
            .filter('completed_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(1);

        if ((instances as List).isNotEmpty) {
          await _openChecklist(instances.first['id'] as String);
        } else {
          final instanceId = await repo.createHousekeepingInstance(
            roomId: widget.room.id,
            hotelId: hotelId,
            staffId: staffId,
          );
          await _openChecklist(instanceId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCleaning = widget.room.housekeepingStatus == 'cleaning';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: isCleaning
                  ? const Color(0xFFFB923C)
                  : const Color(0xFFF87171),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'חדר ${widget.room.roomNumber}${widget.room.floor != null ? " · קומה ${widget.room.floor}" : ""}',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCleaning ? 'בניקיון' : 'ממתין לניקוי',
                  style: TextStyle(
                    color: isCleaning
                        ? const Color(0xFFFB923C)
                        : const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton(
                  onPressed: _handleTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: isCleaning
                        ? const Color(0xFFFB923C)
                        : const Color(0xFFC9A84C),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: Text(isCleaning ? 'המשך' : 'התחל'),
                ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/housekeeping/presentation/housekeeping_staff_screen.dart
git commit -m "feat: add HousekeepingStaffScreen with assigned rooms and checklist integration"
```

---

## Task 7: Navigation + Widget Tests

**Files:**
- Modify: `lib/features/home/presentation/home_screen.dart`
- Modify: `test/features/housekeeping/housekeeping_test.dart`

- [ ] **Step 1: Write widget tests**

Add to `test/features/housekeeping/housekeeping_test.dart`:

```dart
// test/features/housekeeping/housekeeping_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/housekeeping/presentation/housekeeping_manager_screen.dart';
import 'package:hotel_app/features/housekeeping/presentation/housekeeping_staff_screen.dart';
import 'package:hotel_app/features/housekeeping/providers/housekeeping_providers.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

void main() {
  group('Room model', () {
    test('fromJson parses assignedTo and assignedToName', () {
      final json = {
        'id': 'r1',
        'hotel_id': 'h1',
        'room_number': '101',
        'floor': 1,
        'room_type': 'standard',
        'status': 'available',
        'notes': null,
        'housekeeping_status': 'dirty',
        'assigned_to': 'user-uuid-123',
        'assigned_to_name': 'Dana Cohen',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final room = Room.fromJson(json);
      expect(room.assignedTo, 'user-uuid-123');
      expect(room.assignedToName, 'Dana Cohen');
    });

    test('fromJson defaults assignedTo to null when absent', () {
      final json = {
        'id': 'r2',
        'hotel_id': 'h1',
        'room_number': '102',
        'status': 'available',
        'housekeeping_status': 'clean',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final room = Room.fromJson(json);
      expect(room.assignedTo, isNull);
      expect(room.assignedToName, isNull);
    });
  });

  Room makeRoom({
    String id = 'r1',
    String roomNumber = '101',
    int? floor = 2,
    String status = 'dirty',
    String? assignedTo,
    String? assignedToName,
  }) =>
      Room(
        id: id,
        hotelId: 'h1',
        roomNumber: roomNumber,
        floor: floor,
        status: 'available',
        housekeepingStatus: status,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        createdAt: DateTime(2026),
      );

  testWidgets('HousekeepingManagerScreen shows loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allHousekeepingRoomsProvider
              .overrideWith((_) => const Stream.empty()),
        ],
        child: const MaterialApp(
          home: HousekeepingManagerScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('HousekeepingManagerScreen shows summary counts', (tester) async {
    final rooms = [
      makeRoom(id: 'r1', roomNumber: '101', status: 'dirty'),
      makeRoom(id: 'r2', roomNumber: '102', status: 'cleaning'),
      makeRoom(id: 'r3', roomNumber: '103', status: 'dirty'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allHousekeepingRoomsProvider
              .overrideWith((_) => Stream.value(rooms)),
          housekeepingStaffProvider.overrideWith((_) async => []),
        ],
        child: const MaterialApp(
          home: HousekeepingManagerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 מלוכלכים'), findsOneWidget);
    expect(find.text('1 בניקיון'), findsOneWidget);
    expect(find.text('0 נקיים'), findsOneWidget);
  });

  testWidgets('HousekeepingManagerScreen shows room cards', (tester) async {
    final rooms = [
      makeRoom(id: 'r1', roomNumber: '205', status: 'dirty', assignedToName: 'Dana Cohen'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allHousekeepingRoomsProvider
              .overrideWith((_) => Stream.value(rooms)),
          housekeepingStaffProvider.overrideWith((_) async => []),
        ],
        child: const MaterialApp(
          home: HousekeepingManagerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('חדר 205'), findsOneWidget);
    expect(find.text('Dana Cohen'), findsOneWidget);
  });

  testWidgets('HousekeepingStaffScreen shows no rooms message when empty',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myAssignedRoomsProvider
              .overrideWith((_) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: HousekeepingStaffScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('אין חדרים להיום ✅'), findsOneWidget);
  });

  testWidgets('HousekeepingStaffScreen shows assigned room card', (tester) async {
    final rooms = [
      makeRoom(id: 'r1', roomNumber: '303', status: 'dirty'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myAssignedRoomsProvider
              .overrideWith((_) => Stream.value(rooms)),
        ],
        child: const MaterialApp(
          home: HousekeepingStaffScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('חדר 303'), findsOneWidget);
    expect(find.text('התחל'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/features/housekeeping/housekeeping_test.dart
```

Expected: widget tests FAIL (screens not yet in routing, provider overrides don't connect).

- [ ] **Step 3: Update home_screen.dart**

Replace `lib/features/home/presentation/home_screen.dart`:

```dart
// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/features/home/presentation/reception_home.dart';
import 'package:hotel_app/features/home/presentation/maintenance_home.dart';
import 'package:hotel_app/features/home/presentation/manager_home.dart';
import 'package:hotel_app/features/housekeeping/presentation/housekeeping_manager_screen.dart';
import 'package:hotel_app/features/housekeeping/presentation/housekeeping_staff_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roleStr = (user?.appMetadata['role'] as String?) ?? 'receptionist';
    final role = UserRole.fromString(roleStr);

    return switch (role.homeScreen) {
      'housekeeping_manager' => const HousekeepingManagerScreen(),
      'housekeeping_staff'   => const HousekeepingStaffScreen(),
      'maintenance'          => const MaintenanceHomeScreen(),
      'manager'              => const ManagerHomeScreen(),
      _                      => const ReceptionHomeScreen(),
    };
  }
}
```

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/home_screen.dart test/features/housekeeping/housekeeping_test.dart
git commit -m "feat: Phase 9 Module 2 — Housekeeping Full Flow complete (manager + staff screens)"
```
