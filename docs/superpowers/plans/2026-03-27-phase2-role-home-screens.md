# Phase 2: Role-Based Home Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single `HomeScreen` with 4 role-specific home screens — each team (Housekeeping, Maintenance, Reception, Manager) sees only their relevant UI.

**Architecture:** `HomeScreen` reads `UserRole` from JWT `appMetadata`, routes to one of 4 dedicated screens. Each screen has its own provider and layout. Security roles (securityManager, securityGuard) share ReceptionHomeScreen with action buttons hidden via existing `role.canClaimAndUpdate` guard.

**Tech Stack:** Flutter 3, Riverpod, Supabase, GoRouter, existing `UserRole` enum in `ticket_status.dart`

---

## Role Mapping

| UserRole | Home Screen |
|---|---|
| `receptionist`, `deputyReception`, `receptionManager`, `securityManager`, `securityGuard` | `ReceptionHomeScreen` |
| `maintenanceTech`, `repairman`, `maintenanceManager` | `MaintenanceHomeScreen` |
| `housekeepingManager` | `HousekeepingHomeScreen` |
| `ceo`, `superAdmin` | `ManagerHomeScreen` |

## File Structure

```
lib/features/home/
  presentation/
    home_screen.dart                    ← MODIFY: role router only
    reception_home.dart                 ← NEW
    maintenance_home.dart               ← NEW
    housekeeping_home.dart              ← NEW
    manager_home.dart                   ← NEW
  providers/
    maintenance_home_provider.dart      ← NEW: open tickets for dept
    housekeeping_home_provider.dart     ← NEW: dirty rooms today
    manager_home_provider.dart          ← NEW: KPI counts

supabase/migrations/
  20260327000001_add_housekeeping_status.sql  ← NEW
```

---

## Task 1: DB Migration — housekeeping_status on rooms

**Files:**
- Create: `supabase/migrations/20260327000001_add_housekeeping_status.sql`

- [ ] **Step 1: Write migration**

```sql
ALTER TABLE rooms
  ADD COLUMN housekeeping_status TEXT NOT NULL DEFAULT 'clean'
  CHECK (housekeeping_status IN ('dirty', 'cleaning', 'clean'));
```

- [ ] **Step 2: Save file and apply in Supabase Dashboard SQL Editor**

Run the SQL above in Supabase Dashboard → SQL Editor.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260327000001_add_housekeeping_status.sql
git commit -m "feat: add housekeeping_status column to rooms"
```

---

## Task 2: RoomModel — add housekeepingStatus field

**Files:**
- Modify: `lib/features/rooms/domain/room_model.dart`

Current `RoomModel` probably has: `id`, `roomNumber`, `floor`, `status`. We add `housekeepingStatus`.

- [ ] **Step 1: Write the failing test**

In `test/features/rooms/room_model_test.dart`:

```dart
test('RoomModel.fromJson parses housekeepingStatus', () {
  final json = {
    'id': 'r1', 'hotel_id': 'h1', 'room_number': '101',
    'floor': 1, 'room_type': 'standard', 'status': 'available',
    'housekeeping_status': 'dirty',
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };
  final room = RoomModel.fromJson(json);
  expect(room.housekeepingStatus, 'dirty');
});

test('RoomModel.fromJson defaults housekeepingStatus to clean', () {
  final json = {
    'id': 'r1', 'hotel_id': 'h1', 'room_number': '101',
    'floor': 1, 'room_type': 'standard', 'status': 'available',
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };
  final room = RoomModel.fromJson(json);
  expect(room.housekeepingStatus, 'clean');
});
```

- [ ] **Step 2: Run to verify fails**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/rooms/room_model_test.dart -v
```

Expected: FAIL — `housekeepingStatus` not found.

- [ ] **Step 3: Add field to RoomModel**

In `lib/features/rooms/domain/room_model.dart`, add:

```dart
final String housekeepingStatus; // 'dirty' | 'cleaning' | 'clean'
```

In constructor: `required this.housekeepingStatus,`

In `fromJson`:
```dart
housekeepingStatus: j['housekeeping_status'] as String? ?? 'clean',
```

- [ ] **Step 4: Run tests to verify pass**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/rooms/room_model_test.dart -v
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/rooms/domain/room_model.dart test/features/rooms/room_model_test.dart
git commit -m "feat: add housekeepingStatus to RoomModel"
```

---

## Task 3: HomeScreen — role router

**Files:**
- Modify: `lib/features/home/presentation/home_screen.dart`

Replace the single tabbed screen with a role-based router. The role comes from `user?.appMetadata['role']`.

- [ ] **Step 1: Write the failing test**

In `test/features/home/home_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';

void main() {
  test('UserRole routes maintenance roles to maintenance', () {
    expect(UserRole.maintenanceTech.homeScreen, 'maintenance');
    expect(UserRole.repairman.homeScreen, 'maintenance');
    expect(UserRole.maintenanceManager.homeScreen, 'maintenance');
  });

  test('UserRole routes housekeeping roles to housekeeping', () {
    expect(UserRole.housekeepingManager.homeScreen, 'housekeeping');
  });

  test('UserRole routes manager roles to manager', () {
    expect(UserRole.ceo.homeScreen, 'manager');
    expect(UserRole.superAdmin.homeScreen, 'manager');
  });

  test('UserRole routes reception/security to reception', () {
    expect(UserRole.receptionist.homeScreen, 'reception');
    expect(UserRole.securityGuard.homeScreen, 'reception');
    expect(UserRole.receptionManager.homeScreen, 'reception');
  });
}
```

- [ ] **Step 2: Run to verify fails**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/home/home_screen_test.dart -v
```

Expected: FAIL — `homeScreen` getter not found.

- [ ] **Step 3: Add homeScreen getter to UserRole**

In `lib/features/tickets/domain/ticket_status.dart`, add inside `UserRole`:

```dart
String get homeScreen {
  if (this == UserRole.housekeepingManager) return 'housekeeping';
  if (this == UserRole.ceo || this == UserRole.superAdmin) return 'manager';
  if (this == UserRole.maintenanceTech ||
      this == UserRole.repairman ||
      this == UserRole.maintenanceManager) return 'maintenance';
  return 'reception'; // receptionist, deputyReception, receptionManager, securityManager, securityGuard
}
```

- [ ] **Step 4: Run tests to verify pass**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/home/home_screen_test.dart -v
```

- [ ] **Step 5: Rewrite HomeScreen as router**

Replace contents of `lib/features/home/presentation/home_screen.dart`:

```dart
// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/features/home/presentation/reception_home.dart';
import 'package:hotel_app/features/home/presentation/maintenance_home.dart';
import 'package:hotel_app/features/home/presentation/housekeeping_home.dart';
import 'package:hotel_app/features/home/presentation/manager_home.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roleStr = (user?.appMetadata['role'] as String?) ?? 'receptionist';
    final role = UserRole.fromString(roleStr);

    return switch (role.homeScreen) {
      'housekeeping' => const HousekeepingHomeScreen(),
      'maintenance'  => const MaintenanceHomeScreen(),
      'manager'      => const ManagerHomeScreen(),
      _              => const ReceptionHomeScreen(),
    };
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/presentation/home_screen.dart lib/features/tickets/domain/ticket_status.dart test/features/home/home_screen_test.dart
git commit -m "feat: role-based home screen router"
```

---

## Task 4: ReceptionHomeScreen

**Files:**
- Create: `lib/features/home/presentation/reception_home.dart`

Reception sees: room grid (their main tool) + my tickets + profile. Security roles see same but action buttons are already hidden by `role.canClaimAndUpdate`.

- [ ] **Step 1: Write the failing test**

In `test/features/home/reception_home_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/home/presentation/reception_home.dart';

void main() {
  testWidgets('ReceptionHomeScreen has 3 nav tabs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ReceptionHomeScreen())),
    );
    await tester.pump();
    final navbar = find.byType(NavigationBar);
    expect(navbar, findsOneWidget);
    final destinations = find.byType(NavigationDestination);
    expect(destinations, findsNWidgets(3));
  });
}
```

- [ ] **Step 2: Run to verify fails**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/home/reception_home_test.dart -v
```

- [ ] **Step 3: Create ReceptionHomeScreen**

```dart
// lib/features/home/presentation/reception_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/rooms/presentation/rooms_grid_screen.dart';
import 'package:hotel_app/features/tickets/presentation/tickets_list_screen.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class ReceptionHomeScreen extends ConsumerStatefulWidget {
  const ReceptionHomeScreen({super.key});
  @override
  ConsumerState<ReceptionHomeScreen> createState() => _ReceptionHomeScreenState();
}

class _ReceptionHomeScreenState extends ConsumerState<ReceptionHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.hotel,           label: l.rooms,     screen: const RoomsGridScreen()),
      (icon: Icons.confirmation_num, label: l.myTickets, screen: const TicketsListScreen()),
      (icon: Icons.person,           label: l.profile,   screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon), label: t.label,
        )).toList(),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/home/reception_home_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/reception_home.dart test/features/home/reception_home_test.dart
git commit -m "feat: ReceptionHomeScreen with rooms + tickets + profile tabs"
```

---

## Task 5: MaintenanceHomeScreen + Provider

**Files:**
- Create: `lib/features/home/presentation/maintenance_home.dart`
- Create: `lib/features/home/providers/maintenance_home_provider.dart`

Maintenance sees: open tickets queue (sorted by priority), their active ticket, profile.

- [ ] **Step 1: Create provider**

```dart
// lib/features/home/providers/maintenance_home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

final maintenanceTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];

  final data = await supabase
      .from('tickets')
      .select('*, room:rooms(room_number)')
      .eq('hotel_id', hotelId)
      .eq('assigned_dept', 'maintenance')
      .inFilter('status', ['open', 'in_progress'])
      .order('priority', ascending: false)
      .order('created_at');

  return (data as List).map((j) => Ticket.fromJson(j as Map<String, dynamic>)).toList();
});
```

- [ ] **Step 2: Write test for provider logic**

In `test/features/home/maintenance_home_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

void main() {
  test('Ticket.fromJson parses maintenance ticket', () {
    final json = {
      'id': 't1', 'hotel_id': 'h1', 'room_id': 'r1',
      'opened_by': 'u1', 'assigned_dept': 'maintenance',
      'title': 'AC broken', 'priority': 'high', 'status': 'open',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };
    final ticket = Ticket.fromJson(json);
    expect(ticket.assignedDept, 'maintenance');
    expect(ticket.status, 'open');
  });
}
```

- [ ] **Step 3: Run test**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/home/maintenance_home_provider_test.dart -v
```

Expected: PASS (Ticket.fromJson already exists).

- [ ] **Step 4: Create MaintenanceHomeScreen**

```dart
// lib/features/home/presentation/maintenance_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/home/providers/maintenance_home_provider.dart';
import 'package:hotel_app/features/tickets/presentation/ticket_card.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class MaintenanceHomeScreen extends ConsumerStatefulWidget {
  const MaintenanceHomeScreen({super.key});
  @override
  ConsumerState<MaintenanceHomeScreen> createState() => _MaintenanceHomeScreenState();
}

class _MaintenanceHomeScreenState extends ConsumerState<MaintenanceHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.queue,   label: 'תור קריאות', screen: const _MaintenanceQueue()),
      (icon: Icons.person,  label: l.profile,    screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon), label: t.label,
        )).toList(),
      ),
    );
  }
}

class _MaintenanceQueue extends ConsumerWidget {
  const _MaintenanceQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(maintenanceTicketsProvider);
    return tickets.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (list) => list.isEmpty
          ? const Center(child: Text('אין קריאות פתוחות'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) => TicketCard(ticket: list[i]),
            ),
    );
  }
}
```

- [ ] **Step 5: Run all tests**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/presentation/maintenance_home.dart lib/features/home/providers/maintenance_home_provider.dart test/features/home/maintenance_home_provider_test.dart
git commit -m "feat: MaintenanceHomeScreen with ticket queue"
```

---

## Task 6: HousekeepingHomeScreen + Provider

**Files:**
- Create: `lib/features/home/presentation/housekeeping_home.dart`
- Create: `lib/features/home/providers/housekeeping_home_provider.dart`

Housekeeping sees: list of dirty/cleaning rooms today, checklist status per room, profile.

- [ ] **Step 1: Create provider**

```dart
// lib/features/home/providers/housekeeping_home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

final dirtyRoomsProvider = FutureProvider<List<RoomModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];

  final data = await supabase
      .from('rooms')
      .select()
      .eq('hotel_id', hotelId)
      .inFilter('housekeeping_status', ['dirty', 'cleaning'])
      .order('room_number');

  return (data as List).map((j) => RoomModel.fromJson(j as Map<String, dynamic>)).toList();
});
```

- [ ] **Step 2: Create HousekeepingHomeScreen**

```dart
// lib/features/home/presentation/housekeeping_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/home/providers/housekeeping_home_provider.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class HousekeepingHomeScreen extends ConsumerStatefulWidget {
  const HousekeepingHomeScreen({super.key});
  @override
  ConsumerState<HousekeepingHomeScreen> createState() => _HousekeepingHomeScreenState();
}

class _HousekeepingHomeScreenState extends ConsumerState<HousekeepingHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.cleaning_services, label: 'חדרים לניקוי', screen: const _DirtyRoomsList()),
      (icon: Icons.person,             label: l.profile,       screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon), label: t.label,
        )).toList(),
      ),
    );
  }
}

class _DirtyRoomsList extends ConsumerWidget {
  const _DirtyRoomsList();

  Color _statusColor(String status) => switch (status) {
    'dirty'    => Colors.red.shade100,
    'cleaning' => Colors.orange.shade100,
    _          => Colors.green.shade100,
  };

  String _statusLabel(String status) => switch (status) {
    'dirty'    => 'מלוכלך',
    'cleaning' => 'בניקוי',
    _          => 'נקי',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(dirtyRoomsProvider);
    return rooms.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (list) => list.isEmpty
          ? const Center(child: Text('אין חדרים לניקוי היום ✅'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final room = list[i];
                return Card(
                  color: _statusColor(room.housekeepingStatus),
                  child: ListTile(
                    leading: const Icon(Icons.hotel),
                    title: Text('חדר ${room.roomNumber}'),
                    subtitle: Text('קומה ${room.floor}'),
                    trailing: Chip(label: Text(_statusLabel(room.housekeepingStatus))),
                  ),
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 3: Run all tests**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/housekeeping_home.dart lib/features/home/providers/housekeeping_home_provider.dart
git commit -m "feat: HousekeepingHomeScreen with dirty rooms list"
```

---

## Task 7: ManagerHomeScreen + Provider

**Files:**
- Create: `lib/features/home/presentation/manager_home.dart`
- Create: `lib/features/home/providers/manager_home_provider.dart`

Manager sees: KPI dashboard (open tickets count, by dept), analytics, users, profile.

- [ ] **Step 1: Create provider**

```dart
// lib/features/home/providers/manager_home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';

class ManagerKpis {
  final int openTickets;
  final int inProgressTickets;
  final int overdueTickets;
  const ManagerKpis({
    required this.openTickets,
    required this.inProgressTickets,
    required this.overdueTickets,
  });
}

final managerKpisProvider = FutureProvider<ManagerKpis>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;

  final query = supabase.from('tickets').select('status, sla_deadline');
  final filtered = hotelId != null
      ? query.eq('hotel_id', hotelId)
      : query; // superAdmin sees all

  final data = await filtered.inFilter('status', ['open', 'in_progress']);
  final list = data as List;
  final now = DateTime.now();

  return ManagerKpis(
    openTickets: list.where((t) => t['status'] == 'open').length,
    inProgressTickets: list.where((t) => t['status'] == 'in_progress').length,
    overdueTickets: list.where((t) {
      final sla = t['sla_deadline'];
      return sla != null && DateTime.parse(sla as String).isBefore(now);
    }).length,
  );
});
```

- [ ] **Step 2: Write test**

In `test/features/home/manager_kpis_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/home/providers/manager_home_provider.dart';

void main() {
  test('ManagerKpis holds counts', () {
    const kpis = ManagerKpis(openTickets: 5, inProgressTickets: 3, overdueTickets: 1);
    expect(kpis.openTickets, 5);
    expect(kpis.overdueTickets, 1);
  });
}
```

- [ ] **Step 3: Run test**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/home/manager_kpis_test.dart -v
```

Expected: PASS.

- [ ] **Step 4: Create ManagerHomeScreen**

```dart
// lib/features/home/presentation/manager_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/home/providers/manager_home_provider.dart';
import 'package:hotel_app/features/analytics/presentation/analytics_screen.dart';
import 'package:hotel_app/features/users/presentation/users_screen.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class ManagerHomeScreen extends ConsumerStatefulWidget {
  const ManagerHomeScreen({super.key});
  @override
  ConsumerState<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends ConsumerState<ManagerHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.dashboard, label: 'דשבורד',   screen: const _ManagerDashboard()),
      (icon: Icons.bar_chart,  label: l.analytics, screen: const AnalyticsScreen()),
      (icon: Icons.people,     label: l.users,     screen: const UsersScreen()),
      (icon: Icons.person,     label: l.profile,   screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon), label: t.label,
        )).toList(),
      ),
    );
  }
}

class _ManagerDashboard extends ConsumerWidget {
  const _ManagerDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(managerKpisProvider);
    return kpis.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (k) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Text('דשבורד מנהל', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Row(children: [
              _KpiCard(label: 'קריאות פתוחות', value: k.openTickets, color: Colors.blue),
              const SizedBox(width: 12),
              _KpiCard(label: 'בטיפול', value: k.inProgressTickets, color: Colors.orange),
              const SizedBox(width: 12),
              _KpiCard(label: 'חריגות SLA', value: k.overdueTickets, color: Colors.red),
            ]),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('$value', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
```

- [ ] **Step 5: Run all tests**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

Expected: all pass, no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/presentation/manager_home.dart lib/features/home/providers/manager_home_provider.dart test/features/home/manager_kpis_test.dart
git commit -m "feat: ManagerHomeScreen with KPI dashboard"
```

---

## Task 8: Final integration test + verify all roles

- [ ] **Step 1: Run full test suite**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

Expected: All tests pass, analyze clean.

- [ ] **Step 2: Build for web to verify compilation**

```bash
cd "/Users/boazsaada/manegmant resapceon" && /Users/boazsaada/flutter/bin/flutter build web --web-renderer html
```

Expected: `✓ Built build/web`

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: Phase 2 complete — role-based home screens (Reception/Maintenance/Housekeeping/Manager)"
```

---

## Verification (Success Criteria)

- [ ] Login as `reception@hotel.com` → sees **ReceptionHomeScreen** (rooms grid + my tickets)
- [ ] Login as `maintenance@hotel.com` → sees **MaintenanceHomeScreen** (ticket queue)
- [ ] Login as `housekeepingManager@hotel.com` → sees **HousekeepingHomeScreen** (dirty rooms)
- [ ] Login as `superadmin@hotel.com` → sees **ManagerHomeScreen** (KPI dashboard + analytics + users)
- [ ] All 32+ Flutter tests pass
- [ ] `flutter analyze` clean
